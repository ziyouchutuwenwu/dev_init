use crate::config::objects::input::StreamConfig;
use serde::{Deserialize, Serialize};

fn default_true() -> bool {
    true
}

fn default_model() -> String {
    "industry".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamObject {
    pub id: String,
    pub url: String,
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default = "default_model")]
    pub model: String,
}

impl From<StreamConfig> for StreamObject {
    fn from(c: StreamConfig) -> Self {
        Self {
            id: c.id,
            url: c.input,
            enabled: c.enabled,
            model: c.model,
        }
    }
}

impl From<StreamObject> for StreamConfig {
    fn from(obj: StreamObject) -> Self {
        Self {
            id: obj.id,
            input: obj.url,
            enabled: obj.enabled,
            model: obj.model,
        }
    }
}
