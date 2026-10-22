use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct AlertConfig {
    pub url: Option<String>,
    pub cooldown_sec: Option<u64>,
    pub timeout_sec: Option<u64>,
}
