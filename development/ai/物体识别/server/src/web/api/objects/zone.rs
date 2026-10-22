use super::roi::RoiObject;
use crate::config::objects::zone::ZoneConfig;
use crate::object_tracker::rules::DetectionRule;
use crate::object_tracker::zone::ZoneLineConfig;
use serde::{Deserialize, Serialize};

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneObject {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default)]
    pub roi: Option<RoiObject>,
    #[serde(default, alias = "trigger_area")]
    pub trigger_line: Option<ZoneLineConfig>,
    #[serde(default)]
    pub target_classes: Vec<String>,
    #[serde(default)]
    pub rules: Vec<DetectionRule>,
}

impl From<ZoneConfig> for ZoneObject {
    fn from(c: ZoneConfig) -> Self {
        Self {
            enabled: c.enabled,
            roi: c.roi.map(RoiObject::from),
            trigger_line: c.trigger_line,
            target_classes: c.target_classes,
            rules: c.rules,
        }
    }
}

impl TryFrom<ZoneObject> for ZoneConfig {
    type Error = String;

    fn try_from(obj: ZoneObject) -> Result<Self, Self::Error> {
        let roi = match obj.roi {
            Some(r) => Some(crate::config::objects::roi::RoiConfig::try_from(r).map_err(|e| e.to_string())?),
            None => None,
        };
        Ok(ZoneConfig {
            enabled: obj.enabled,
            roi,
            trigger_line: obj.trigger_line,
            target_classes: obj.target_classes,
            rules: obj.rules,
        })
    }
}
