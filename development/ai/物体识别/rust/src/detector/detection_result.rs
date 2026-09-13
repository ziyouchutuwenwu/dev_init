use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionObject {
    pub class_id: Option<i32>,
    pub label: Option<String>,
    pub confidence: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rel_box: Option<Vec<f64>>,
    pub box_coord: Vec<f64>,
}

pub type DetectionItem = DetectionObject;


#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionResult {
    pub id: String,
    pub timestamp: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_idx: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pts_ms: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_width: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_height: Option<i32>,
    pub detections: Vec<serde_json::Value>,
}

impl DetectionResult {
    pub fn new(timestamp: i64, id: impl Into<String>, detections: Vec<serde_json::Value>) -> Self {
        Self {
            id: id.into(),
            timestamp,
            frame_idx: None,
            pts_ms: None,
            frame_width: Some(1920),
            frame_height: Some(1080),
            detections,
        }
    }

    pub fn now(id: impl Into<String>, detections: Vec<serde_json::Value>) -> Self {
        Self {
            id: id.into(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            frame_idx: None,
            pts_ms: None,
            frame_width: Some(1920),
            frame_height: Some(1080),
            detections,
        }
    }
}
