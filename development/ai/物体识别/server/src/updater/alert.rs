use crate::config::YamlConfig;

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

    let cfg_path = crate::config::get_global_config_path();
    let mut config = YamlConfig::load_or_default(&cfg_path);
    config.set_alert(alert_url, cooldown_sec, timeout_sec);
    if let Err(e) = config.save() {
        log::warn!("[updater:alert] 保存告警配置到 {cfg_path} 异常: {e}");
        return Err(format!("保存告警配置失败: {e}"));
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
    let config = YamlConfig::load_or_default(config_path);
    let (url, cooldown, timeout) = config.get_alert();
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

