use anyhow::{Context, Result};
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebDavConfig {
    pub url: String,
    pub username: String,
    pub password: Option<String>,
    pub path: Option<String>,
}

fn get_config_file_path() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let path = base_dirs
        .home_dir()
        .join("AppData")
        .join("Roaming")
        .join("EndSwitcher");

    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path.join("config.json"))
}

fn get_accounts_dir() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let path = base_dirs
        .home_dir()
        .join("AppData")
        .join("Roaming")
        .join("EndSwitcher")
        .join("accounts");
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

    // 本地结构：accounts/<alias>
    // 远端结构：/webdav_url/EndSwitcherConfig/<alias>

    let remote_dir = format!(
        "{}{}",
        config.path.as_deref().unwrap(),
        "/EndSwitcherConfig"
    );
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

    let accounts = crate::api::endfield::get_account_list()?;
    for acc in accounts {
        let alias = acc.alias;
        let cache_file = get_accounts_dir()?.join(&alias);
        let file_url = format!("{}{}", base_url, alias);
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
    let remote_dir = format!(
        "{}{}",
        config.path.as_deref().unwrap(),
        "/EndSwitcherConfig"
    );
    let base_url = if config.url.ends_with('/') {
        format!("{}{}/", config.url, remote_dir)
    } else {
        format!("{}/{}/", config.url, remote_dir)
    };

    // 1. 发送 PROPFIND 请求获取目录下所有文件
    let propfind_body = r#"<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:resourcetype/>
  </D:prop>
</D:propfind>"#;

    let mut req = client
        .request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), &base_url)
        .header("Depth", "1")
        .header("Content-Type", "text/xml")
        .body(propfind_body);

    if let Some(pwd) = &config.password {
        req = req.basic_auth(&config.username, Some(pwd));
    } else if !config.username.is_empty() {
        req = req.basic_auth(&config.username, None::<&str>);
    }

    let res = req.send().await?;
    if !res.status().is_success() {
        anyhow::bail!("Failed to execute PROPFIND on WebDAV server. Check path or permissions.");
    }

    let xml_response = res.text().await?;

    // 2. 解析 XML 提取所有文件路径 (排除目录)
    use quick_xml::events::Event;
    use quick_xml::reader::Reader;

    let mut reader = Reader::from_str(&xml_response);
    reader.trim_text(true);

    let mut in_href = false;
    let mut in_collection = false;
    let mut current_href = String::new();
    let mut buf = Vec::new();
    let mut files_to_download = Vec::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let name = e.name();
                let name_ref = name.as_ref();
                if name_ref == b"D:href" || name_ref == b"href" {
                    in_href = true;
                } else if name_ref == b"D:collection" || name_ref == b"collection" {
                    in_collection = true;
                }
            }
            Ok(Event::Text(e)) => {
                if in_href {
                    current_href = e.unescape()?.into_owned();
                }
            }
            Ok(Event::End(ref e)) => {
                let name = e.name();
                let name_ref = name.as_ref();
                if name_ref == b"D:href" || name_ref == b"href" {
                    in_href = false;
                } else if name_ref == b"D:response" || name_ref == b"response" {
                    // 如果是一个文件（不是 collection），且不是当前目录（通常以 / 结尾或等同于 base_url）
                    if !in_collection && !current_href.ends_with('/') {
                        // 从 href 提取文件名
                        if let Some(filename) = current_href.split('/').last() {
                            if !filename.is_empty() && filename != "accounts.json" {
                                // 进行 URL 解码（如果目录包含中文等）
                                if let Ok(decoded) = urlencoding::decode(filename) {
                                    files_to_download.push(decoded.into_owned());
                                } else {
                                    files_to_download.push(filename.to_string());
                                }
                            }
                        }
                    }
                    in_collection = false;
                    current_href.clear();
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => anyhow::bail!("XML parse error: {:?}", e),
            _ => (),
        }
        buf.clear();
    }

    let accounts_dir = get_accounts_dir()?;

    // 3. 挨个下载文件
    for filename in files_to_download {
        let file_url = format!("{}{}", base_url, urlencoding::encode(&filename));
        let mut req = client.get(&file_url);
        if let Some(pwd) = &config.password {
            req = req.basic_auth(&config.username, Some(pwd));
        } else if !config.username.is_empty() {
            req = req.basic_auth(&config.username, None::<&str>);
        }

        let res = req.send().await?;
        if res.status().is_success() {
            let data = res.bytes().await?;
            fs::write(accounts_dir.join(&filename), data)?;
        }
    }

    Ok(())
}
