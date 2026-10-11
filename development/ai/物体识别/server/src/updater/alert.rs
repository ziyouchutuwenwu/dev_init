use std::path::Path;

pub async fn update_alert_config(
    alert_url: Option<&str>,
    cooldown_sec: Option<u64>,
    timeout_sec: Option<u64>,
) -> Result<(), String> {
    if let Some(url) = alert_url {
        let trimmed = url.trim().to_string();
        crate::on_detected::set_alert_url(&trimmed);
    }
    if let Some(cd) = cooldown_sec {
        crate::on_detected::set_alert_cooldown_sec(Some(cd));
    }
    if let Some(to) = timeout_sec {
        crate::on_detected::set_alert_timeout_sec(Some(to));
    }

    let cfg_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
    if let Err(e) = save_alert_config_to_yaml(&cfg_path, alert_url, cooldown_sec, timeout_sec) {
        log::warn!("[updater:alert] 保存告警配置到 {cfg_path} 异常: {e}");
    } else {
        log::info!("[updater:alert] 成功热更新告警配置并持久化至 {cfg_path}");
    }

    Ok(())
}

pub async fn update_alert_url(alert_url: &str) -> Result<String, String> {
    let trimmed = alert_url.trim().to_string();
    update_alert_config(Some(&trimmed), None, None).await?;
    Ok(trimmed)
}

pub fn get_alert_url() -> String {
    crate::on_detected::get_alert_url()
}

pub fn get_alert_cooldown_sec() -> Option<u64> {
    crate::on_detected::get_alert_cooldown_sec()
}

pub fn get_alert_timeout_sec() -> Option<u64> {
    crate::on_detected::get_alert_timeout_sec()
}

pub fn init_alert_config_from_config(config_path: &str) {
    let (url, cooldown, timeout) = load_alert_config_from_yaml(config_path);
    if let Some(url) = url {
        log::info!("[updater:alert] 从配置文件载入告警回调地址: '{url}'");
        crate::on_detected::set_alert_url(url);
    }
    if let Some(cooldown) = cooldown {
        log::info!("[updater:alert] 从配置文件载入告警最少间隔时间: {cooldown}s");
        crate::on_detected::set_alert_cooldown_sec(Some(cooldown));
    }
    if let Some(timeout) = timeout {
        log::info!("[updater:alert] 从配置文件载入告警请求超时: {timeout}s");
        crate::on_detected::set_alert_timeout_sec(Some(timeout));
    }
}

pub fn init_alert_url_from_config(config_path: &str) {
    init_alert_config_from_config(config_path);
}

fn save_alert_config_to_yaml<P: AsRef<Path>>(
    path: P,
    alert_url: Option<&str>,
    cooldown_sec: Option<u64>,
    timeout_sec: Option<u64>,
) -> std::io::Result<()> {
    let file_path = path.as_ref();
    let content = std::fs::read_to_string(file_path).unwrap_or_default();
    let updated = update_yaml_alert_config(&content, alert_url, cooldown_sec, timeout_sec);
    std::fs::write(file_path, &updated)?;

    if file_path != Path::new("deploy/config.yaml") && Path::new("deploy/config.yaml").exists() {
        let _ = std::fs::write("deploy/config.yaml", &updated);
    }
    if file_path != Path::new("server/config.yaml") && Path::new("server/config.yaml").exists() {
        let _ = std::fs::write("server/config.yaml", &updated);
    }
    Ok(())
}

fn load_alert_config_from_yaml<P: AsRef<Path>>(
    path: P,
) -> (Option<String>, Option<u64>, Option<u64>) {
    let Ok(content) = std::fs::read_to_string(path) else {
        return (None, None, None);
    };
    let mut url = None;
    let mut cooldown = None;
    let mut timeout = None;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("alert_url:") {
            let val = trimmed.trim_start_matches("alert_url:").trim();
            let clean = val.trim_matches('"').trim_matches('\'').trim();
            if !clean.is_empty() {
                url = Some(clean.to_string());
            }
        } else if trimmed.starts_with("alert_cooldown_sec:") {
            let val = trimmed.trim_start_matches("alert_cooldown_sec:").trim();
            if let Ok(num) = val.parse::<u64>() {
                cooldown = Some(num);
            }
        } else if trimmed.starts_with("alert_timeout_sec:") {
            let val = trimmed.trim_start_matches("alert_timeout_sec:").trim();
            if let Ok(num) = val.parse::<u64>() {
                timeout = Some(num);
            }
        }
    }
    (url, cooldown, timeout)
}

fn update_yaml_alert_config(
    content: &str,
    alert_url: Option<&str>,
    cooldown_sec: Option<u64>,
    timeout_sec: Option<u64>,
) -> String {
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();

    if let Some(url) = alert_url {
        let trimmed = url.trim();
        let alert_line = format!("alert_url: \"{trimmed}\"");
        let pos = lines.iter().position(|l| l.trim().starts_with("alert_url:"));
        if let Some(idx) = pos {
            lines[idx] = alert_line;
        } else {
            lines.push(alert_line);
        }
    }

    if let Some(cd) = cooldown_sec {
        let cd_line = format!("alert_cooldown_sec: {cd}");
        let pos = lines
            .iter()
            .position(|l| l.trim().starts_with("alert_cooldown_sec:"));
        if let Some(idx) = pos {
            lines[idx] = cd_line;
        } else {
            lines.push(cd_line);
        }
    }

    if let Some(to) = timeout_sec {
        let to_line = format!("alert_timeout_sec: {to}");
        let pos = lines
            .iter()
            .position(|l| l.trim().starts_with("alert_timeout_sec:"));
        if let Some(idx) = pos {
            lines[idx] = to_line;
        } else {
            lines.push(to_line);
        }
    }

    let mut result = lines.join("\n");
    if !result.ends_with('\n') {
        result.push('\n');
    }
    result
}
