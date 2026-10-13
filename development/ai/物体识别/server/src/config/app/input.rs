use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(transparent)]
pub struct InputConfig {
    pub streams: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
}

impl InputConfig {
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
