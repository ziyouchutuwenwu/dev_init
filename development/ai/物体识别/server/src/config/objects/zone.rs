use crate::object_tracker::rules::DetectionRule;
use crate::object_tracker::zone::ZoneLineConfig;
use serde::{Deserialize, Serialize};
use super::roi::RoiConfig;

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneConfig {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default)]
    pub model: Option<String>,
    #[serde(default)]
    pub roi: Option<RoiConfig>,
    #[serde(default, alias = "trigger_area")]
    pub trigger_line: Option<ZoneLineConfig>,
    #[serde(default)]
    pub target_classes: Vec<String>,
    #[serde(default)]
    pub rules: Vec<DetectionRule>,
}

impl Default for ZoneConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            model: None,
            roi: None,
            trigger_line: None,
            target_classes: Vec::new(),
            rules: Vec::new(),
        }
    }
}
