use crate::config::base::ConfigSection;
use crate::config::trigger::HttpPostRule;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct TriggerConfig {
    #[serde(default)]
    pub http_post: HashMap<String, HttpPostRule>,
}

impl TriggerConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Option<Self> {
        let sec = section?;

        let mut http_post = HashMap::new();
        if let Some(http_sec) = sec.get_child("http_post") {
            for (target_name, target_sec) in http_sec.children() {
                http_post.insert(
                    target_name.clone(),
                    HttpPostRule::from_section(target_sec),
                );
            }
        }

        if http_post.is_empty() {
            None
        } else {
            Some(Self {
                http_post,
            })
        }
    }
}
