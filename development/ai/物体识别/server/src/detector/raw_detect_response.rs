use serde::Deserialize;

#[derive(Deserialize)]
pub struct RawDetectResponse {
    pub frame_width: Option<i32>,
    pub frame_height: Option<i32>,
    pub frame_idx: Option<u64>,
    pub pts_ms: Option<i64>,
    #[serde(default)]
    pub detections: Vec<serde_json::Value>,
}
