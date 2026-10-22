use crate::object_tracker::rules::DetectionRule;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct TriggerConfig {
    pub target_classes: Vec<String>,
    pub rules: Vec<DetectionRule>,
}
