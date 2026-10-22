use crate::object_tracker::rules::DetectionRule;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct DetectionObject {
    #[serde(default)]
    pub target_classes: Vec<String>,
    #[serde(default)]
    pub rules: Vec<DetectionRule>,
}
