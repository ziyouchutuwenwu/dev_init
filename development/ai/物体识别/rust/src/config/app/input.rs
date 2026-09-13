use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InputConfig {
    pub streams: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
}

impl InputConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Result<Self, String> {
        let sec = match section {
            Some(s) => s,
            None => return Err("未在配置文件中找到 input 配置段".to_string()),
        };

        let mut streams = HashMap::new();
        for (k, v) in sec.values() {
            if !k.is_empty() && !v.is_empty() {
                streams.insert(k.clone(), v.clone());
            }
        }

        if streams.is_empty() {
            return Err("未在配置文件中找到任何有效的视频流定义".to_string());
        }

        Ok(Self { streams })
    }

    pub fn get_streams(&self) -> Vec<StreamConfig> {
        let mut sorted_keys: Vec<&String> = self.streams.keys().collect();
        sorted_keys.sort();
        sorted_keys
            .into_iter()
            .map(|k| StreamConfig {
                id: k.clone(),
                input: self.streams[k].clone(),
            })
            .collect()
    }
}
