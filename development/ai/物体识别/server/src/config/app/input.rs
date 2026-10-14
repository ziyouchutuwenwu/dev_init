use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Default)]
#[serde(transparent)]
pub struct InputConfig {
    pub streams: HashMap<String, String>,
}

impl<'de> Deserialize<'de> for InputConfig {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let opt: Option<HashMap<String, String>> = Option::deserialize(deserializer)?;
        Ok(InputConfig {
            streams: opt.unwrap_or_default(),
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
    #[serde(default = "default_true", alias = "ai_enabled")]
    pub enabled: bool,
}

fn default_true() -> bool {
    true
}

impl StreamConfig {
    pub fn new(id: impl Into<String>, input: impl Into<String>, enabled: bool) -> Self {
        Self {
            id: id.into(),
            input: input.into(),
            enabled,
        }
    }
}

impl InputConfig {
    pub fn get_streams(&self) -> Vec<StreamConfig> {
        let mut sorted_keys: Vec<&String> = self.streams.keys().collect();
        sorted_keys.sort();
        let config_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
        sorted_keys
            .into_iter()
            .map(|k| {
                let zone_cfg = crate::object_tracker::ZoneConfig::load_from_yaml_file(&config_path, k);
                StreamConfig {
                    id: k.clone(),
                    input: self.streams[k].clone(),
                    enabled: zone_cfg.enabled,
                }
            })
            .collect()
    }
}
