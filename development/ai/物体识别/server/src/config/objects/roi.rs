use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(untagged)]
pub enum RoiConfig {
    Rect([f64; 4]),
    Polygon(Vec<[f64; 2]>),
}
