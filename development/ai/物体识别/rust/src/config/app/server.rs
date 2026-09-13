use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

impl ServerConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Self {
        let sec = match section {
            Some(s) => s,
            None => {
                return Self {
                    host: "0.0.0.0".to_string(),
                    port: 8181,
                };
            }
        };

        let host = sec.get_string("host").unwrap_or_else(|| "0.0.0.0".to_string());
        let port = sec.get_u16("port").unwrap_or(8181);

        Self { host, port }
    }

    pub fn http_addr(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}
