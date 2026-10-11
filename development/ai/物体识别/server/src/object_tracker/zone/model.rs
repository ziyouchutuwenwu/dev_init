use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub enum CrossingDirection {
    #[serde(rename = "any")]
    Any,
    #[serde(rename = "forward")]
    Forward,
    #[serde(rename = "backward")]
    Backward,
}

impl Default for CrossingDirection {
    fn default() -> Self {
        Self::Any
    }
}

pub type AreaTriggerDirection = CrossingDirection;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneLineConfig {
    pub line: [[f64; 2]; 2],
    #[serde(default)]
    pub direction: CrossingDirection,
}

pub type AreaTriggerConfig = ZoneLineConfig;
