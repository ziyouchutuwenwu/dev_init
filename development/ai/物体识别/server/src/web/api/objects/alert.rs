use crate::config::objects::alert::AlertConfig;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct AlertObject {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cooldown_sec: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub timeout_sec: Option<u64>,
}

impl From<AlertConfig> for AlertObject {
    fn from(c: AlertConfig) -> Self {
        Self {
            url: c.url,
            cooldown_sec: c.cooldown_sec,
            timeout_sec: c.timeout_sec,
        }
    }
}

impl From<AlertObject> for AlertConfig {
    fn from(obj: AlertObject) -> Self {
        Self {
            url: obj.url,
            cooldown_sec: obj.cooldown_sec,
            timeout_sec: obj.timeout_sec,
        }
    }
}
