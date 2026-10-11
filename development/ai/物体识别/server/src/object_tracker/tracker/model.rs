use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrackedObject {
    pub track_id: u64,
    pub class_id: Option<i32>,
    pub label: Option<String>,
    pub confidence: f64,
    pub rel_box: [f64; 4],
    pub box_coord: Vec<f64>,
    pub center: [f64; 2],
    pub trajectory: Vec<[f64; 2]>,
    pub hits: usize,
    pub lost_frames: usize,
    pub age: usize,
}

#[derive(Debug, Clone)]
pub struct DetectionInput {
    pub class_id: Option<i32>,
    pub label: Option<String>,
    pub confidence: f64,
    pub rel_box: [f64; 4],
    pub box_coord: Vec<f64>,
}

#[derive(Debug, Clone)]
pub struct TrackerConfig {
    pub iou_threshold: f64,
    pub max_lost_frames: usize,
    pub max_trajectory_len: usize,
    pub min_hits_to_confirm: usize,
    pub max_center_dist: f64,
}

impl Default for TrackerConfig {
    fn default() -> Self {
        Self {
            iou_threshold: 0.25,
            max_lost_frames: 20,
            max_trajectory_len: 30,
            min_hits_to_confirm: 1,
            max_center_dist: 0.15,
        }
    }
}
