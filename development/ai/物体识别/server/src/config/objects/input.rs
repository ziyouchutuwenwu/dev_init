use serde::{Deserialize, Serialize};

fn default_model() -> String {
    "industry".to_string()
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
    pub enabled: bool,
    #[serde(default = "default_model")]
    pub model: String,
}
