use anyhow::{Context, Result};
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebDavConfig {
    pub url: String,
    pub username: String,
    pub password: Option<String>,
    pub path: Option<String>,
}

fn get_config_file_path() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let path = base_dirs.home_dir().join("AppData").join("Roaming").join("EndSwitcher");
    
    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path.join("config.json"))
}

fn get_accounts_dir() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let path = base_dirs.home_dir().join("AppData").join("Roaming").join("EndSwitcher").join("accounts");
    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path)
}

pub fn save_webdav_config(config: WebDavConfig) -> anyhow::Result<()> {
    let path = get_config_file_path()?;
    let data = serde_json::to_string_pretty(&config)?;
    fs::write(path, data)?;
    Ok(())
}

pub fn load_webdav_config() -> anyhow::Result<WebDavConfig> {
    let path = get_config_file_path()?;
    if !path.exists() {
        anyhow::bail!("Config file not found");
    }
    let data = fs::read_to_string(path)?;
    let config: WebDavConfig = serde_json::from_str(&data)?;
    Ok(config)
}

// 简单的 WebDAV 同步逻辑

pub async fn sync_to_webdav() -> anyhow::Result<()> {
    let config = load_webdav_config()?;
    let client = reqwest::Client::new();
    
    // 我们采取简单的策略：把本地的 accounts 目录下的资料逐个上传。
    // 由于只有一级 alias 和 login_cache，结构非常简单：
    // /webdav_url/EndSwitcherBackup/<alias>/login_cache
    
    let remote_dir = config.path.as_deref().unwrap_or("EndSwitcherBackup");
    let base_url = if config.url.ends_with('/') {
        format!("{}{}/", config.url, remote_dir)
    } else {
        format!("{}/{}/", config.url, remote_dir)
    };
    
    // 确保远端文件夹存在 (MKCOL)
    let mkcol_req = client.request(reqwest::Method::from_bytes(b"MKCOL").unwrap(), &base_url);
    let mut mkcol_req = mkcol_req;
    if let Some(pwd) = &config.password {
        mkcol_req = mkcol_req.basic_auth(&config.username, Some(pwd));
    } else if !config.username.is_empty() {
        mkcol_req = mkcol_req.basic_auth(&config.username, None::<&str>);
    }
    let _ = mkcol_req.send().await; // 忽略错误，可能远端已经存在文件夹
    
    let accounts_dir = get_accounts_dir()?;
    for entry in fs::read_dir(accounts_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            if let Some(alias) = path.file_name().and_then(|n| n.to_str()) {
                let cache_file = path.join("login_cache");
                if cache_file.exists() {
                    // Mkcol for this alias
                    let alias_url = format!("{}{}/", base_url, alias);
                    let mut req = client.request(reqwest::Method::from_bytes(b"MKCOL").unwrap(), &alias_url);
                    if let Some(pwd) = &config.password {
                        req = req.basic_auth(&config.username, Some(pwd));
                    } else if !config.username.is_empty() {
                        req = req.basic_auth(&config.username, None::<&str>);
                    }
                    let _ = req.send().await;
                    
                    // Put login_cache
                    let file_url = format!("{}login_cache", alias_url);
                    let mut req = client.put(&file_url);
                    if let Some(pwd) = &config.password {
                        req = req.basic_auth(&config.username, Some(pwd));
                    } else if !config.username.is_empty() {
                        req = req.basic_auth(&config.username, None::<&str>);
                    }
                    
                    let file_data = fs::read(&cache_file)?;
                    let res = req.body(file_data).send().await?;
                    if !res.status().is_success() {
                        let status = res.status();
                        let text = res.text().await.unwrap_or_default();
                        anyhow::bail!("Failed to upload {}: {} - {}", alias, status, text);
                    }
                }
            }
        }
    }
    Ok(())
}

// 注意：这只是一个骨架，由于从 WebDAV 下载通常需要支持 PROPFIND 解析 XML 来获取目录列表，
// 或者是拉取一个已知结构的列表。这里简单起见，可以考虑前端不做全量下载，而是依赖一个配置。
// 为了简化设计，我们在上传时多上传一个 accounts.json 文件存元数据。

pub async fn sync_to_webdav_with_manifest() -> anyhow::Result<()> {
    // 调用前面的同步
    sync_to_webdav().await?;
    
    let config = load_webdav_config()?;
    let client = reqwest::Client::new();
    let remote_dir = config.path.as_deref().unwrap_or("EndSwitcherBackup");
    let base_url = if config.url.ends_with('/') {
        format!("{}{}/", config.url, remote_dir)
    } else {
        format!("{}/{}/", config.url, remote_dir)
    };
    
    // 生成 manifest
    let accounts = crate::api::endfield::get_account_list()?;
    let manifest_str = serde_json::to_string(&accounts)?;
    
    // Put manifest
    let manifest_url = format!("{}accounts.json", base_url);
    let mut req = client.put(&manifest_url);
    if let Some(pwd) = &config.password {
        req = req.basic_auth(&config.username, Some(pwd));
    } else if !config.username.is_empty() {
        req = req.basic_auth(&config.username, None::<&str>);
    }
    
    let res = req.body(manifest_str).send().await?;
    if !res.status().is_success() {
        anyhow::bail!("Failed to upload manifest");
    }
    
    Ok(())
}

pub async fn sync_from_webdav() -> anyhow::Result<()> {
    let config = load_webdav_config()?;
    let client = reqwest::Client::new();
    let remote_dir = config.path.as_deref().unwrap_or("EndSwitcherBackup");
    let base_url = if config.url.ends_with('/') {
        format!("{}{}/", config.url, remote_dir)
    } else {
        format!("{}/{}/", config.url, remote_dir)
    };
    
    // 先获取 manifest
    let manifest_url = format!("{}accounts.json", base_url);
    let mut req = client.get(&manifest_url);
    if let Some(pwd) = &config.password {
        req = req.basic_auth(&config.username, Some(pwd));
    } else if !config.username.is_empty() {
        req = req.basic_auth(&config.username, None::<&str>);
    }
    
    let res = req.send().await?;
    if !res.status().is_success() {
        anyhow::bail!("Failed to download manifest: cloud backup might not exist");
    }
    
    let manifest_str = res.text().await?;
    let accounts: Vec<crate::api::endfield::AccountInfo> = serde_json::from_str(&manifest_str)?;
    
    let accounts_dir = get_accounts_dir()?;
    
    // 挨个下载
    for acc in accounts {
        let file_url = format!("{}{}/login_cache", base_url, acc.alias);
        let mut req = client.get(&file_url);
        if let Some(pwd) = &config.password {
            req = req.basic_auth(&config.username, Some(pwd));
        } else if !config.username.is_empty() {
            req = req.basic_auth(&config.username, None::<&str>);
        }
        
        let res = req.send().await?;
        if res.status().is_success() {
            let data = res.bytes().await?;
            let target_dir = accounts_dir.join(&acc.alias);
            if !target_dir.exists() {
                fs::create_dir_all(&target_dir)?;
            }
            fs::write(target_dir.join("login_cache"), data)?;
        }
    }
    
    Ok(())
}
