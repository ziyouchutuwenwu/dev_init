use std::collections::HashMap;
use super::math::{calculate_iou, euclidean_dist};
use super::model::{DetectionInput, TrackedObject, TrackerConfig};

pub struct ObjectTracker {
    next_id: u64,
    tracks: HashMap<u64, TrackedObject>,
    config: TrackerConfig,
}

impl ObjectTracker {
    pub fn new() -> Self {
        Self::with_config(TrackerConfig::default())
    }

    pub fn with_config(config: TrackerConfig) -> Self {
        Self {
            next_id: 1,
            tracks: HashMap::new(),
            config,
        }
    }

    pub fn reset(&mut self) {
        self.tracks.clear();
        self.next_id = 1;
    }

    pub fn update(&mut self, detections: Vec<DetectionInput>) -> Vec<TrackedObject> {
        let det_count = detections.len();
        let track_ids: Vec<u64> = self.tracks.keys().copied().collect();
        let track_count = track_ids.len();

        let mut matched_tracks: HashMap<u64, usize> = HashMap::new();
        let mut matched_dets: HashMap<usize, u64> = HashMap::new();

        if track_count > 0 && det_count > 0 {
            let dim = track_count.max(det_count);
            let mut weights = pathfinding::matrix::Matrix::new(dim, dim, 0i64);

            for (t_idx, &t_id) in track_ids.iter().enumerate() {
                let track = &self.tracks[&t_id];
                for (d_idx, det) in detections.iter().enumerate() {
                    if track.class_id.is_some() && det.class_id.is_some() && track.class_id != det.class_id {
                        continue;
                    }
                    let iou = calculate_iou(&track.rel_box, &det.rel_box);
                    let center_d = [
                        (det.rel_box[0] + det.rel_box[2]) / 2.0,
                        (det.rel_box[1] + det.rel_box[3]) / 2.0,
                    ];
                    let dist = euclidean_dist(&track.center, &center_d);

                    let mut score = iou;
                    if iou < self.config.iou_threshold && dist < self.config.max_center_dist {
                        score = 0.20 + (1.0 - (dist / self.config.max_center_dist)) * 0.10;
                    }

                    if score >= 0.20 {
                        weights[(t_idx, d_idx)] = (score * 10000.0) as i64;
                    }
                }
            }

            let (_, assignment) = pathfinding::kuhn_munkres::kuhn_munkres(&weights);
            for (t_idx, &d_idx) in assignment.iter().enumerate() {
                if t_idx < track_count && d_idx < det_count && weights[(t_idx, d_idx)] > 0 {
                    let t_id = track_ids[t_idx];
                    matched_tracks.insert(t_id, d_idx);
                    matched_dets.insert(d_idx, t_id);
                }
            }
        }

        for (t_id, d_idx) in matched_tracks {
            let det = &detections[d_idx];
            let track = self.tracks.get_mut(&t_id).unwrap();
            let new_center = [
                (det.rel_box[0] + det.rel_box[2]) / 2.0,
                (det.rel_box[1] + det.rel_box[3]) / 2.0,
            ];

            track.rel_box = det.rel_box;
            track.box_coord = det.box_coord.clone();
            track.confidence = det.confidence;
            if det.class_id.is_some() {
                track.class_id = det.class_id;
            }
            if det.label.is_some() {
                track.label = det.label.clone();
            }
            track.center = new_center;
            track.trajectory.push(new_center);
            if track.trajectory.len() > self.config.max_trajectory_len {
                track.trajectory.remove(0);
            }
            track.hits += 1;
            track.lost_frames = 0;
            track.age += 1;
        }

        for &t_id in &track_ids {
            if !matched_dets.values().any(|&id| id == t_id) {
                let track = self.tracks.get_mut(&t_id).unwrap();
                track.lost_frames += 1;
                track.age += 1;
            }
        }

        for (d_idx, det) in detections.into_iter().enumerate() {
            if !matched_dets.contains_key(&d_idx) {
                let track_id = self.next_id;
                self.next_id += 1;

                let center = [
                    (det.rel_box[0] + det.rel_box[2]) / 2.0,
                    (det.rel_box[1] + det.rel_box[3]) / 2.0,
                ];

                let new_track = TrackedObject {
                    track_id,
                    class_id: det.class_id,
                    label: det.label,
                    confidence: det.confidence,
                    rel_box: det.rel_box,
                    box_coord: det.box_coord,
                    center,
                    trajectory: vec![center],
                    hits: 1,
                    lost_frames: 0,
                    age: 1,
                };
                self.tracks.insert(track_id, new_track);
            }
        }

        let max_lost = self.config.max_lost_frames;
        self.tracks.retain(|_, t| t.lost_frames <= max_lost);

        let min_hits = self.config.min_hits_to_confirm;
        self.tracks
            .values()
            .filter(|t| t.lost_frames == 0 && t.hits >= min_hits)
            .cloned()
            .collect()
    }
}

impl Default for ObjectTracker {
    fn default() -> Self {
        Self::new()
    }
}
