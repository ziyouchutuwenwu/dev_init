use crate::config;

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

    if let Err(e) = config::alert::save_config(alert_url, cooldown_sec, timeout_sec) {
        log::warn!("[updater:alert] 保存告警配置异常: {e}");
        return Err(format!("保存告警配置失败: {e}"));
    } else {
        log::info!("[updater:alert] 成功热更新告警配置并持久化");
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

pub fn init_alert_config_from_config(_config_path: &str) {
    let alert_cfg = config::alert::load_config();
    if let Some(url) = alert_cfg.url {
        log::info!("[updater:alert] 从配置文件载入告警回调地址: '{url}'");
        crate::on_detected::set_alert_url(url);
    }
    if let Some(cooldown) = alert_cfg.cooldown_sec {
        log::info!("[updater:alert] 从配置文件载入告警最少间隔时间: {cooldown}s");
        crate::on_detected::set_alert_cooldown_sec(Some(cooldown));
    }
    if let Some(timeout) = alert_cfg.timeout_sec {
        log::info!("[updater:alert] 从配置文件载入告警请求超时: {timeout}s");
        crate::on_detected::set_alert_timeout_sec(Some(timeout));
    }
}

pub fn init_alert_url_from_config(config_path: &str) {
    init_alert_config_from_config(config_path);
}

