use std::sync::Arc;
use super::DetectCWrapper;
use super::detection_result::DetectionResult;

pub struct FrameDetector {
    detect_wrapper: Arc<DetectCWrapper>,
    channel_id: u32,
    stream_id: String,
    default_width: i32,
    default_height: i32,
}

impl FrameDetector {
    pub fn with_channel(
        detect_wrapper: Arc<DetectCWrapper>,
        channel_id: u32,
        stream_id: impl Into<String>,
    ) -> Self {
        Self {
            detect_wrapper,
            channel_id,
            stream_id: stream_id.into(),
            default_width: 1920,
            default_height: 1080,
        }
    }

    pub fn channel_id(&self) -> u32 {
        self.channel_id
    }

    pub fn stream_id(&self) -> &str {
        &self.stream_id
    }

    pub fn feed_packet(&self, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        self.detect_wrapper.bin_to_img_stream(self.channel_id, packet_data, frame_idx, pts_ms)
    }

    pub fn detect_latest(&self) -> Result<DetectionResult, String> {
        let (raw_json, out_frame_idx, out_pts_ms) = self.detect_wrapper.detect_img_bin(self.channel_id)?;
        let parsed = match serde_json::from_str::<serde_json::Value>(&raw_json) {
            Ok(v) => v,
            Err(_) => serde_json::Value::Array(Vec::new()),
        };

        let mut frame_w = Some(self.default_width);
        let mut frame_h = Some(self.default_height);
        let mut f_idx = out_frame_idx;
        let mut f_pts = out_pts_ms;
        let mut detections = Vec::new();

        if let serde_json::Value::Object(map) = parsed {
            if let Some(w) = parse_dimension(map.get("frame_width")) {
                frame_w = Some(w);
            }
            if let Some(h) = parse_dimension(map.get("frame_height")) {
                frame_h = Some(h);
            }
            if let Some(idx) = parse_u64(map.get("frame_idx")) {
                f_idx = idx;
            }
            if let Some(pts) = parse_i64(map.get("pts_ms")) {
                f_pts = pts;
            }
            if let Some(serde_json::Value::Array(arr)) = map.get("detections") {
                detections = arr.clone();
            }
        }

        let fw_f = match frame_w {
            Some(w) => w as f64,
            None => self.default_width as f64,
        };
        let fh_f = match frame_h {
            Some(h) => h as f64,
            None => self.default_height as f64,
        };

        for detection in &mut detections {
            normalize_detection_box(detection, fw_f, fh_f);
        }

        Ok(DetectionResult {
            id: self.stream_id.clone(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            frame_idx: Some(f_idx),
            pts_ms: Some(f_pts),
            frame_width: frame_w,
            frame_height: frame_h,
            detections,
        })
    }
}

fn parse_dimension(val: Option<&serde_json::Value>) -> Option<i32> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    match num.as_i64() {
        Some(v) if v > 0 => Some(v as i32),
        _ => None,
    }
}

fn parse_u64(val: Option<&serde_json::Value>) -> Option<u64> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    num.as_u64()
}

fn parse_i64(val: Option<&serde_json::Value>) -> Option<i64> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    num.as_i64()
}

fn normalize_detection_box(detection: &mut serde_json::Value, fw_f: f64, fh_f: f64) {
    let det_obj = match detection {
        serde_json::Value::Object(map) => map,
        _ => return,
    };

    if det_obj.contains_key("rel_box") {
        return;
    }

    let box_arr = match det_obj.get("box") {
        Some(serde_json::Value::Array(arr)) if arr.len() >= 4 => arr,
        _ => return,
    };

    let x1 = match box_arr[0].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let y1 = match box_arr[1].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let x2 = match box_arr[2].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let y2 = match box_arr[3].as_f64() {
        Some(v) => v,
        None => 0.0,
    };

    if x1 <= 1.0 && y1 <= 1.0 && x2 <= 1.0 && y2 <= 1.0 && (x2 > 0.0 || y2 > 0.0) {
        det_obj.insert("rel_box".to_string(), serde_json::json!([x1, y1, x2, y2]));
        return;
    }

    if fw_f > 0.0 && fh_f > 0.0 {
        let rx1 = (x1 / fw_f).clamp(0.0, 1.0);
        let ry1 = (y1 / fh_f).clamp(0.0, 1.0);
        let rx2 = (x2 / fw_f).clamp(0.0, 1.0);
        let ry2 = (y2 / fh_f).clamp(0.0, 1.0);
        det_obj.insert("rel_box".to_string(), serde_json::json!([rx1, ry1, rx2, ry2]));
    }
}
