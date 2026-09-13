use super::input::InputConfig;
use super::server::ServerConfig;
use super::trigger::TriggerConfig;
use crate::config::base::ConfigParser;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub input: InputConfig,
    pub server: ServerConfig,
    #[serde(default)]
    pub trigger: Option<TriggerConfig>,
}

impl AppConfig {
    pub fn load_from_file<P: AsRef<std::path::Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let parser = ConfigParser::from_file(&path)?;

        let input_sec = parser.get_section("input");
        let input = InputConfig::from_section(input_sec)?;

        let server_sec = parser.get_section("server");
        let server = ServerConfig::from_section(server_sec);

        let trigger_sec = parser.get_section("trigger");
        let trigger = TriggerConfig::from_section(trigger_sec);

        Ok(Self {
            input,
            server,
            trigger,
        })
    }
}
