use std::path::Path;

pub const DEFAULT_CONFIG_PATH: &str = "config.yaml";
pub const ALT_CONFIG_PATH: &str = "config.yml";

pub fn get_config_path() -> String {
    if Path::new(ALT_CONFIG_PATH).exists() && !Path::new(DEFAULT_CONFIG_PATH).exists() {
        return ALT_CONFIG_PATH.to_string();
    }
    DEFAULT_CONFIG_PATH.to_string()
}
