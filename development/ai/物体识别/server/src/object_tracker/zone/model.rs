use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Default)]
pub enum CrossingDirection {
    #[serde(rename = "any")]
    #[default]
    Any,
    #[serde(rename = "forward")]
    Forward,
    #[serde(rename = "backward")]
    Backward,
}

pub type AreaTriggerDirection = CrossingDirection;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneLineConfig {
    pub line: [[f64; 2]; 2],
    #[serde(default)]
    pub direction: CrossingDirection,
}

pub type AreaTriggerConfig = ZoneLineConfig;
