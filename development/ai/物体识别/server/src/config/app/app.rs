use super::input::InputConfig;
use super::server::ServerConfig;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub input: InputConfig,
    pub server: ServerConfig,
    #[serde(default)]
    pub trigger: Option<serde_yaml::Value>,
}

impl AppConfig {
    pub fn load_from_file<P: AsRef<std::path::Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(path)?;
        let config: Self = serde_yaml::from_str(&content)?;
        Ok(config)
    }
}
