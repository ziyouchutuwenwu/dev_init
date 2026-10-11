use crate::detector::detection_result::DetectionResult;
use crate::object_tracker::{
    DetectionInput, ObjectTracker, TrackedObject, ZoneConfig,
};
use crate::on_detected::dispatcher::DetectedDispatcher;
use std::collections::HashMap;
use std::sync::{Arc, LazyLock, Mutex};
use tokio::sync::{broadcast, RwLock};

static GLOBAL_ZONE_HANDLERS: LazyLock<Mutex<HashMap<String, Arc<StreamTrackContext>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

pub struct StreamTrackContext {
    pub stream_id: String,
    pub config: Arc<RwLock<ZoneConfig>>,
    pub tracker: Arc<Mutex<ObjectTracker>>,
}

impl StreamTrackContext {
    pub fn new(stream_id: &str, initial_config: ZoneConfig) -> Self {
        Self {
            stream_id: stream_id.to_string(),
            config: Arc::new(RwLock::new(initial_config)),
            tracker: Arc::new(Mutex::new(ObjectTracker::new())),
        }
    }
}

pub struct ObjectTrackHandler;

impl ObjectTrackHandler {
    pub fn get_context(stream_id: &str) -> Option<Arc<StreamTrackContext>> {
        GLOBAL_ZONE_HANDLERS.lock().unwrap().get(stream_id).cloned()
    }

    pub fn get_or_create_context(stream_id: &str, default_config: ZoneConfig) -> Arc<StreamTrackContext> {
        let mut map = GLOBAL_ZONE_HANDLERS.lock().unwrap();
        map.entry(stream_id.to_string())
            .or_insert_with(|| Arc::new(StreamTrackContext::new(stream_id, default_config)))
            .clone()
    }

    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        processed_dispatcher: Arc<DetectedDispatcher>,
        initial_config: ZoneConfig,
    ) -> Arc<StreamTrackContext> {
        let stream_id = stream_id.into();
        let ctx = Self::get_or_create_context(&stream_id, initial_config);
        let ctx_clone = Arc::clone(&ctx);
        let s_id = stream_id.clone();

        tokio::spawn(async move {
            run_track_loop(s_id, receiver, processed_dispatcher, ctx_clone).await;
        });

        ctx
    }
}

async fn run_track_loop(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    processed_dispatcher: Arc<DetectedDispatcher>,
    ctx: Arc<StreamTrackContext>,
) {
    log::info!("[object_track_handler:{stream_id}] 目标跟踪与触发区域处理器已启动");

    loop {
        match receiver.recv().await {
            Ok(result) => {
                let enriched = process_frame(&stream_id, &result, &ctx).await;
                processed_dispatcher.publish(Arc::new(enriched));
            }
            Err(broadcast::error::RecvError::Lagged(skipped)) => {
                log::warn!("[object_track_handler:{stream_id}] 消费过慢，跳过 {skipped} 帧");
            }
            Err(broadcast::error::RecvError::Closed) => {
                log::info!("[object_track_handler:{stream_id}] 数据流通道已关闭，退出处理循环");
                break;
            }
        }
    }
}

async fn process_frame(
    _stream_id: &str,
    raw_result: &DetectionResult,
    ctx: &StreamTrackContext,
) -> DetectionResult {
    let zone_cfg = ctx.config.read().await.clone();

    let mut detection_inputs = Vec::new();
    let fw = raw_result.frame_width.unwrap_or(1920) as f64;
    let fh = raw_result.frame_height.unwrap_or(1080) as f64;

    for val in &raw_result.detections {
        if let Some(obj) = parse_detection_item(val, fw, fh) {
            let center = [
                (obj.rel_box[0] + obj.rel_box[2]) / 2.0,
                (obj.rel_box[1] + obj.rel_box[3]) / 2.0,
            ];

            if zone_cfg.enabled {
                if let Some(rect) = zone_cfg.get_trigger_box() {
                    let x_min = rect[0].min(rect[2]);
                    let x_max = rect[0].max(rect[2]);
                    let y_min = rect[1].min(rect[3]);
                    let y_max = rect[1].max(rect[3]);
                    if center[0] < x_min || center[0] > x_max || center[1] < y_min || center[1] > y_max {
                        continue;
                    }
                } else if let Some(roi) = &zone_cfg.roi {
                    if !roi.contains_point(center) {
                        continue;
                    }
                }
            }

            detection_inputs.push(obj);
        }
    }

    let tracked_objects: Vec<TrackedObject> = {
        let mut tracker = ctx.tracker.lock().unwrap();
        tracker.update(detection_inputs)
    };

    let mut enriched_detections = Vec::with_capacity(tracked_objects.len());
    for track in &tracked_objects {
        let item_json = serde_json::json!({
            "track_id": track.track_id,
            "class_id": track.class_id,
            "label": track.label,
            "confidence": track.confidence,
            "rel_box": track.rel_box,
            "box": track.box_coord,
            "center": track.center,
            "trajectory": track.trajectory,
            "hits": track.hits,
            "age": track.age,
        });
        enriched_detections.push(item_json);
    }

    DetectionResult {
        id: raw_result.id.clone(),
        timestamp: raw_result.timestamp,
        frame_idx: raw_result.frame_idx,
        pts_ms: raw_result.pts_ms,
        frame_width: raw_result.frame_width,
        frame_height: raw_result.frame_height,
        detections: enriched_detections,
        zone_config: Some(serde_json::to_value(&zone_cfg).unwrap_or_default()),
    }
}

fn parse_detection_item(val: &serde_json::Value, fw: f64, fh: f64) -> Option<DetectionInput> {
    let obj = val.as_object()?;

    let class_id = obj.get("class_id").and_then(|v| v.as_i64()).map(|n| n as i32);
    let label = obj.get("label").and_then(|v| v.as_str()).map(|s| s.to_string());
    let confidence = obj.get("confidence").and_then(|v| v.as_f64()).unwrap_or(0.0);

    let mut rel_box = [0.0, 0.0, 0.0, 0.0];
    let mut box_coord = Vec::new();

    if let Some(r_arr) = obj.get("rel_box").and_then(|v| v.as_array()) {
        if r_arr.len() >= 4 {
            rel_box[0] = r_arr[0].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
            rel_box[1] = r_arr[1].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
            rel_box[2] = r_arr[2].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
            rel_box[3] = r_arr[3].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
        }
    }

    if let Some(b_arr) = obj.get("box").and_then(|v| v.as_array()) {
        for b in b_arr {
            if let Some(n) = b.as_f64() {
                box_coord.push(n);
            }
        }
        if (rel_box[2] - rel_box[0]).abs() < 1e-6 && box_coord.len() >= 4 && fw > 0.0 && fh > 0.0 {
            rel_box[0] = (box_coord[0] / fw).clamp(0.0, 1.0);
            rel_box[1] = (box_coord[1] / fh).clamp(0.0, 1.0);
            rel_box[2] = (box_coord[2] / fw).clamp(0.0, 1.0);
            rel_box[3] = (box_coord[3] / fh).clamp(0.0, 1.0);
        }
    }

    Some(DetectionInput {
        class_id,
        label,
        confidence,
        rel_box,
        box_coord,
    })
}
