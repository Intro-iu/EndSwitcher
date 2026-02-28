use anyhow::{Context, Result};
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccountInfo {
    pub alias: String,
    pub updated_at: i64,
}

// 帮助函数：获取游戏数据目录 AppData\LocalLow\Hypergryph\Endfield
fn get_endfield_dir() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let path = base_dirs
        .home_dir()
        .join("AppData")
        .join("LocalLow")
        .join("Hypergryph")
        .join("Endfield");
    
    if !path.exists() {
        anyhow::bail!("Endfield directory not found");
    }
    Ok(path)
}

// 帮助函数：获取应用自身数据存储目录 AppData\Roaming\EndSwitcher
fn get_app_data_dir() -> Result<PathBuf> {
    let base_dirs = BaseDirs::new().context("Could not find base directories")?;
    let _path = base_dirs.config_dir().join("EndSwitcher");
    // 对 Windows 而言 config_dir 一般就是 AppData\Roaming
    let path = base_dirs.home_dir().join("AppData").join("Roaming").join("EndSwitcher");
    
    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path)
}

fn get_accounts_dir() -> Result<PathBuf> {
    let path = get_app_data_dir()?.join("accounts");
    if !path.exists() {
        fs::create_dir_all(&path)?;
    }
    Ok(path)
}

fn get_account_cache_file(alias: &str) -> Result<PathBuf> {
    Ok(get_accounts_dir()?.join(alias))
}

// 查找当前游戏内的 login_cache 文件所在的路径
pub fn find_login_cache_path() -> Result<String> {
    let endfield_dir = get_endfield_dir()?;
    for entry in fs::read_dir(endfield_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                if name.starts_with("sdk_data_") {
                    let cache_file = path.join("login_cache");
                    if cache_file.exists() && cache_file.is_file() {
                        return Ok(cache_file.to_string_lossy().to_string());
                    }
                }
            }
        }
    }
    anyhow::bail!("login_cache file not found in any sdk_data_* directory")
}

// ============== 核心曝光 API ==============

/// 获取当前所有已保存的账号列表
pub fn get_account_list() -> anyhow::Result<Vec<AccountInfo>> {
    let accounts_dir = get_accounts_dir()?;
    let mut accounts = Vec::new();
    
    for entry in fs::read_dir(accounts_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            if let Some(alias) = path.file_name().and_then(|n| n.to_str()) {
                let metadata = fs::metadata(&path)?;
                let updated_at = metadata.modified()
                    .unwrap_or_else(|_| SystemTime::now())
                    .duration_since(UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs() as i64;

                accounts.push(AccountInfo {
                    alias: alias.to_string(),
                    updated_at,
                });
            }
        }
    }
    
    accounts.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
    Ok(accounts)
}

/// 保存当前登录的账号
pub fn save_current_account(alias: String) -> anyhow::Result<()> {
    let current_cache = find_login_cache_path()?;
    let target_file = get_account_cache_file(&alias)?;
    fs::copy(&current_cache, &target_file)?;
    Ok(())
}

/// 切换到指定账号
pub fn switch_to_account(alias: String) -> anyhow::Result<()> {
    // 确保有文件存放的路径可用，即使找不到现在的 cache_path 也可以把文件写入第一个 sdk_data_ 目录！
    // 不过，为了安全起见，通常切换时游戏中本来就已经有一个 cache_path
    let endfield_dir = get_endfield_dir()?;
    let mut target_game_sdk_dir = None;
    
    for entry in fs::read_dir(&endfield_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                if name.starts_with("sdk_data_") {
                    target_game_sdk_dir = Some(path.clone());
                    break;
                }
            }
        }
    }
    
    let target_game_sdk_dir = target_game_sdk_dir
        .context("No sdk_data_* directory found in game folder. Please start the game at least once.")?;
        
    let source_cache = get_account_cache_file(&alias)?;
    if !(source_cache.exists() && source_cache.is_file()) {
        anyhow::bail!("Saved account not found");
    }
    
    let game_cache_file = target_game_sdk_dir.join("login_cache");
    fs::copy(&source_cache, &game_cache_file)?;
    
    Ok(())
}

/// 删除指定账号
pub fn delete_account(alias: String) -> anyhow::Result<()> {
    let target_file = get_account_cache_file(&alias)?;
    if target_file.exists() && target_file.is_file() {
        fs::remove_file(&target_file)?;
    }
    Ok(())
}
