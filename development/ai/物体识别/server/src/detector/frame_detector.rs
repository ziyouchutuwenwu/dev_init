use std::sync::Arc;
use super::DetectWrapper;
use super::detection_result::DetectionResult;

pub struct FrameDetector {
    detect_wrapper: Arc<DetectWrapper>,
    channel_id: u32,
    stream_id: String,
    default_width: i32,
    default_height: i32,
    flush_epoch: std::sync::atomic::AtomicU64,
    session_epoch: std::sync::atomic::AtomicU64,
    channel_released: std::sync::atomic::AtomicBool,
}

impl FrameDetector {
    pub fn with_channel(
        detect_wrapper: Arc<DetectWrapper>,
        channel_id: u32,
        stream_id: impl Into<String>,
    ) -> Self {
        Self {
            detect_wrapper,
            channel_id,
            stream_id: stream_id.into(),
            default_width: 1920,
            default_height: 1080,
            flush_epoch: std::sync::atomic::AtomicU64::new(0),
            session_epoch: std::sync::atomic::AtomicU64::new(0),
            channel_released: std::sync::atomic::AtomicBool::new(false),
        }
    }

    pub fn next_session_epoch(&self) -> u64 {
        self.session_epoch.fetch_add(1, std::sync::atomic::Ordering::SeqCst) + 1
    }

    pub fn session_epoch(&self) -> u64 {
        self.session_epoch.load(std::sync::atomic::Ordering::Relaxed)
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

    pub fn create_channel(&self) -> Result<(), String> {
        self.detect_wrapper.create_channel(self.channel_id)
    }

    pub fn create_channel_with_codec(&self, codec: &str) -> Result<(), String> {
        self.detect_wrapper.create_channel_with_codec(self.channel_id, codec)
    }

    pub fn release_channel(&self) -> Result<(), String> {
        if self.channel_released.swap(true, std::sync::atomic::Ordering::SeqCst) {
            return Ok(());
        }
        self.detect_wrapper.release_channel(self.channel_id)
    }

    pub fn flush(&self) -> Result<(), String> {
        self.flush_epoch.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        self.detect_wrapper.flush_channel(self.channel_id)
    }

    pub fn flush_epoch(&self) -> u64 {
        self.flush_epoch.load(std::sync::atomic::Ordering::Relaxed)
    }

    pub fn detect_latest(&self) -> Result<Option<DetectionResult>, String> {
        let (raw_json_opt, out_frame_idx, out_pts_ms) = self.detect_wrapper.detect_img_bin(self.channel_id)?;
        let raw_json = match raw_json_opt {
            Some(s) if !s.is_empty() => s,
            _ => return Ok(None),
        };

        let mut parsed = match serde_json::from_str::<RawDetectResponse>(&raw_json) {
            Ok(v) => v,
            Err(_) => return Ok(None),
        };

        let frame_w = parsed.frame_width.filter(|&w| w > 0).or(Some(self.default_width));
        let frame_h = parsed.frame_height.filter(|&h| h > 0).or(Some(self.default_height));
        let f_idx = parsed.frame_idx.unwrap_or(out_frame_idx);
        let f_pts = parsed.pts_ms.unwrap_or(out_pts_ms);

        let fw_f = frame_w.unwrap_or(self.default_width) as f64;
        let fh_f = frame_h.unwrap_or(self.default_height) as f64;

        for detection in &mut parsed.detections {
            normalize_detection_box(detection, fw_f, fh_f);
        }

        Ok(Some(DetectionResult {
            id: self.stream_id.clone(),
            timestamp: crate::current_time_millis(),
            frame_idx: Some(f_idx),
            pts_ms: Some(f_pts),
            frame_width: frame_w,
            frame_height: frame_h,
            detections: parsed.detections,
            zone_config: None,
        }))
    }
}

#[derive(serde::Deserialize)]
struct RawDetectResponse {
    frame_width: Option<i32>,
    frame_height: Option<i32>,
    frame_idx: Option<u64>,
    pts_ms: Option<i64>,
    #[serde(default)]
    detections: Vec<serde_json::Value>,
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
    let x1 = box_arr[0].as_f64().unwrap_or(0.0);
    let y1 = box_arr[1].as_f64().unwrap_or(0.0);
    let x2 = box_arr[2].as_f64().unwrap_or(0.0);
    let y2 = box_arr[3].as_f64().unwrap_or(0.0);

    let x_min = x1.min(x2);
    let x_max = x1.max(x2);
    let y_min = y1.min(y2);
    let y_max = y1.max(y2);

    if x_max <= 1.0 && y_max <= 1.0 && (x_max > 0.0 || y_max > 0.0) {
        let rx1 = x_min.clamp(0.0, 1.0);
        let ry1 = y_min.clamp(0.0, 1.0);
        let rx2 = x_max.clamp(0.0, 1.0);
        let ry2 = y_max.clamp(0.0, 1.0);
        det_obj.insert("rel_box".to_string(), serde_json::json!([rx1, ry1, rx2, ry2]));
        return;
    }

    if fw_f > 0.0 && fh_f > 0.0 {
        let rx1 = (x_min / fw_f).clamp(0.0, 1.0);
        let ry1 = (y_min / fh_f).clamp(0.0, 1.0);
        let rx2 = (x_max / fw_f).clamp(0.0, 1.0);
        let ry2 = (y_max / fh_f).clamp(0.0, 1.0);
        det_obj.insert("rel_box".to_string(), serde_json::json!([rx1, ry1, rx2, ry2]));
    }
}
