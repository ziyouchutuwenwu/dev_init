use serde_yaml::Value;
use std::io;
use super::r#const::*;
use super::YamlConfig;

pub use super::objects::ServerConfig;

pub fn load_config() -> ServerConfig {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml(&cfg)
}

pub fn save_config(host: &str, port: u16) -> io::Result<()> {
    let path = super::get_config_path();
    let mut cfg = YamlConfig::load_or_default(&path);
    apply_to_yaml(host, port, &mut cfg);
    cfg.save()
}

pub fn from_yaml(cfg: &YamlConfig) -> ServerConfig {
    let host = cfg
        .get_nested(&[KEY_SERVER, KEY_HOST])
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| DEFAULT_SERVER_HOST.to_string());
    let port = cfg
        .get_nested(&[KEY_SERVER, KEY_PORT])
        .and_then(|v| v.as_u64())
        .map(|n| n as u16)
        .unwrap_or(DEFAULT_SERVER_PORT);
    ServerConfig { host, port }
}

pub fn apply_to_yaml(host: &str, port: u16, cfg: &mut YamlConfig) {
    cfg.set_nested(&[KEY_SERVER, KEY_HOST], Value::String(host.to_string()));
    cfg.set_nested(&[KEY_SERVER, KEY_PORT], Value::Number((port as u64).into()));
}

pub fn http_addr() -> String {
    let cfg = load_config();
    format!("{}:{}", cfg.host, cfg.port)
}
