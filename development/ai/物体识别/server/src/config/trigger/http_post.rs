use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HttpPostRule {
    pub url: String,
}

impl HttpPostRule {
    pub fn from_section(section: &ConfigSection) -> Self {
        let url = section
            .get_string("url")
            .unwrap_or_else(|| "http://127.0.0.1:4000/api/alert".to_string());

        Self { url }
    }
}
