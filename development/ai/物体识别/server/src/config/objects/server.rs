use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: crate::config::r#const::DEFAULT_SERVER_HOST.to_string(),
            port: crate::config::r#const::DEFAULT_SERVER_PORT,
        }
    }
}
