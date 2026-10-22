use serde_yaml::{Mapping, Value};
use std::io;
use super::r#const::*;
use super::YamlConfig;

pub use super::objects::AlertConfig;

pub fn load_config() -> AlertConfig {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml(&cfg)
}

pub fn save_config(
    alert_url: Option<&str>,
    cooldown_sec: Option<u64>,
    timeout_sec: Option<u64>,
) -> io::Result<()> {
    let path = super::get_config_path();
    let mut cfg = YamlConfig::load_or_default(&path);
    apply_to_yaml(alert_url, cooldown_sec, timeout_sec, &mut cfg);
    cfg.save()
}

pub fn from_yaml(cfg: &YamlConfig) -> AlertConfig {
    let url = cfg
        .get_nested(&[KEY_ALERT, KEY_URL])
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .or_else(|| cfg.get_str(KEY_ALERT_URL).map(|s| s.to_string()))
        .or_else(|| cfg.get_str(KEY_ALERT_CALLBACK_URL).map(|s| s.to_string()))
        .filter(|s| !s.trim().is_empty());

    let cooldown_sec = cfg
        .get_nested(&[KEY_ALERT, KEY_COOLDOWN_SEC])
        .and_then(|v| v.as_u64())
        .or_else(|| cfg.get_u64(KEY_ALERT_COOLDOWN_SEC));

    let timeout_sec = cfg
        .get_nested(&[KEY_ALERT, KEY_TIMEOUT_SEC])
        .and_then(|v| v.as_u64())
        .or_else(|| cfg.get_u64(KEY_ALERT_TIMEOUT_SEC));

    AlertConfig {
        url,
        cooldown_sec,
        timeout_sec,
    }
}

pub fn apply_to_yaml(
    alert_url: Option<&str>,
    cooldown_sec: Option<u64>,
    timeout_sec: Option<u64>,
    cfg: &mut YamlConfig,
) {
    cfg.remove(KEY_ALERT_URL);
    cfg.remove(KEY_ALERT_CALLBACK_URL);
    cfg.remove(KEY_ALERT_COOLDOWN_SEC);
    cfg.remove(KEY_ALERT_TIMEOUT_SEC);

    let url_clean = alert_url.filter(|s| !s.trim().is_empty());
    if url_clean.is_none() && cooldown_sec.is_none() && timeout_sec.is_none() {
        cfg.remove(KEY_ALERT);
        return;
    }

    let mut alert_map = Mapping::new();
    if let Some(url) = url_clean {
        alert_map.insert(
            Value::String(KEY_URL.to_string()),
            Value::String(url.to_string()),
        );
    }
    if let Some(cd) = cooldown_sec {
        alert_map.insert(
            Value::String(KEY_COOLDOWN_SEC.to_string()),
            Value::Number(cd.into()),
        );
    }
    if let Some(to) = timeout_sec {
        alert_map.insert(
            Value::String(KEY_TIMEOUT_SEC.to_string()),
            Value::Number(to.into()),
        );
    }

    if !cfg.root().is_mapping() {
        *cfg.root_mut() = Value::Mapping(Mapping::new());
    }
    if let Some(root_map) = cfg.root_mut().as_mapping_mut() {
        root_map.insert(Value::String(KEY_ALERT.to_string()), Value::Mapping(alert_map));
    }
}
