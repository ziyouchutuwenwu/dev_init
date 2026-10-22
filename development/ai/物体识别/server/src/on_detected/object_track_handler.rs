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

    pub fn get_all_contexts() -> Vec<Arc<StreamTrackContext>> {
        GLOBAL_ZONE_HANDLERS.lock().unwrap().values().cloned().collect()
    }

    pub fn remove_context(stream_id: &str) -> Option<Arc<StreamTrackContext>> {
        GLOBAL_ZONE_HANDLERS.lock().unwrap().remove(stream_id)
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

    if !zone_cfg.enabled {
        return DetectionResult {
            id: raw_result.id.clone(),
            timestamp: raw_result.timestamp,
            frame_idx: raw_result.frame_idx,
            pts_ms: raw_result.pts_ms,
            frame_width: raw_result.frame_width,
            frame_height: raw_result.frame_height,
            detections: Vec::new(),
            zone_config: Some(serde_json::to_value(&zone_cfg).unwrap_or_default()),
        };
    }

    let mut detection_inputs = Vec::new();
    let fw = raw_result.frame_width.unwrap_or(1920) as f64;
    let fh = raw_result.frame_height.unwrap_or(1080) as f64;

    for val in &raw_result.detections {
        if let Some(obj) = parse_detection_item(val, fw, fh) {
            detection_inputs.push(obj);
        }
    }

    let tracked_objects: Vec<TrackedObject> = {
        let mut tracker = ctx.tracker.lock().unwrap();
        tracker.update(detection_inputs)
    };

    let mut enriched_detections = Vec::with_capacity(tracked_objects.len());

    let mut in_roi_list = Vec::with_capacity(tracked_objects.len());
    let mut crossed_list = Vec::with_capacity(tracked_objects.len());

    for track in &tracked_objects {
        let center = track.center;
        let in_roi = if let Some(roi) = &zone_cfg.roi {
            roi.contains_point(center)
        } else {
            true
        };
        in_roi_list.push(in_roi);

        let crossed = if let Some(line_cfg) = &zone_cfg.trigger_line {
            if track.trajectory.len() >= 2 {
                let prev = track.trajectory[track.trajectory.len() - 2];
                let curr = track.center;
                if crate::object_tracker::zone::math::segments_intersect(
                    prev,
                    curr,
                    line_cfg.line[0],
                    line_cfg.line[1],
                ) {
                    let dir_val = crate::object_tracker::zone::math::compute_crossing_direction(
                        prev,
                        curr,
                        line_cfg.line[0],
                        line_cfg.line[1],
                    );
                    match line_cfg.direction {
                        crate::object_tracker::CrossingDirection::Any => true,
                        crate::object_tracker::CrossingDirection::Forward => dir_val > 0.0,
                        crate::object_tracker::CrossingDirection::Backward => dir_val < 0.0,
                    }
                } else {
                    false
                }
            } else {
                false
            }
        } else {
            false
        };
        crossed_list.push(crossed);
    }

    if !zone_cfg.rules.is_empty() && zone_cfg.enabled {
        let alerts = crate::object_tracker::evaluate_rules(&tracked_objects, &in_roi_list, &zone_cfg.rules);

        let mut alert_map: HashMap<u64, Vec<crate::object_tracker::RuleAlert>> = HashMap::new();
        for alert in &alerts {
            if let Some(tid) = alert.track_id {
                alert_map.entry(tid).or_default().push(alert.clone());
            }
        }

        let class_in_targets = |targets: &[String], label: Option<&str>, class_id: Option<i32>| -> bool {
            if targets.is_empty() {
                return true;
            }
            if let Some(l) = label {
                if targets.iter().any(|c| {
                    c.eq_ignore_ascii_case(l)
                        || (l.eq_ignore_ascii_case("person") && (c == "人员目标" || c.eq_ignore_ascii_case("person")))
                        || (l.eq_ignore_ascii_case("forklift") && (c == "工业搬运叉车" || c == "叉车" || c.eq_ignore_ascii_case("forklift")))
                        || (l.eq_ignore_ascii_case("hardhat") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("helmet")))
                        || (l.eq_ignore_ascii_case("helmet") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("hardhat")))
                        || (l.eq_ignore_ascii_case("no-hardhat") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-helmet")))
                        || (l.eq_ignore_ascii_case("no-helmet") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-hardhat")))
                        || (l.eq_ignore_ascii_case("safety-vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("vest")))
                        || (l.eq_ignore_ascii_case("vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("safety-vest")))
                        || (l.eq_ignore_ascii_case("no-safety-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-vest")))
                        || (l.eq_ignore_ascii_case("no-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-safety-vest")))
                        || (l.eq_ignore_ascii_case("license_plate") && (c == "机动车车牌" || c == "车牌" || c.eq_ignore_ascii_case("plate") || c.eq_ignore_ascii_case("license_plate")))
                        || (l.eq_ignore_ascii_case("plate") && (c == "机动车车牌" || c == "车牌" || c.eq_ignore_ascii_case("plate") || c.eq_ignore_ascii_case("license_plate")))
                        || (l.eq_ignore_ascii_case("vehicle") && (c == "机动车辆" || c == "机动车" || c == "车辆" || c.eq_ignore_ascii_case("vehicle") || c.eq_ignore_ascii_case("car")))
                }) {
                    return true;
                }
            }
            if let Some(cid) = class_id {
                let s = cid.to_string();
                if targets.iter().any(|c| c == &s) {
                    return true;
                }
            }
            false
        };

        let rule_alert_allowed = |alert: &crate::object_tracker::RuleAlert, target_classes: &[String]| -> bool {
            if target_classes.is_empty() {
                return true;
            }
            target_classes.iter().any(|c| {
                c.eq_ignore_ascii_case(&alert.alert_type)
                    || c.eq_ignore_ascii_case(&alert.rule_id)
                    || c.eq_ignore_ascii_case(&alert.rule_name)
                    || alert.label.as_ref().is_some_and(|l| {
                        c.eq_ignore_ascii_case(l)
                            || (l.eq_ignore_ascii_case("person") && (c == "人员目标" || c.eq_ignore_ascii_case("person")))
                            || (l.eq_ignore_ascii_case("forklift") && (c == "工业搬运叉车" || c == "叉车" || c.eq_ignore_ascii_case("forklift")))
                            || (l.eq_ignore_ascii_case("hardhat") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("helmet")))
                            || (l.eq_ignore_ascii_case("helmet") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("hardhat")))
                            || (l.eq_ignore_ascii_case("no-hardhat") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-helmet")))
                            || (l.eq_ignore_ascii_case("no-helmet") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-hardhat")))
                            || (l.eq_ignore_ascii_case("safety-vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("vest")))
                            || (l.eq_ignore_ascii_case("vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("safety-vest")))
                            || (l.eq_ignore_ascii_case("no-safety-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-vest")))
                            || (l.eq_ignore_ascii_case("no-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-vest")))
                    })
                    || (alert.rule_id == "rule_hardhat" && (c.eq_ignore_ascii_case("no-hardhat") || c.eq_ignore_ascii_case("hardhat") || c == "未戴安全帽"))
                    || (alert.rule_id == "rule_safety_vest" && (c.eq_ignore_ascii_case("no-safety-vest") || c.eq_ignore_ascii_case("safety-vest") || c == "未穿反光衣"))
                    || (alert.rule_id == "rule_forklift_collision" && (c.eq_ignore_ascii_case("forklift") || c == "叉车"))
                    || (alert.rule_id == "rule_smoking_phone" && (c.eq_ignore_ascii_case("smoking") || c.eq_ignore_ascii_case("phone-call") || c == "抽烟" || c == "打电话"))
                    || (alert.rule_id == "rule_fire_smoke" && (c.eq_ignore_ascii_case("fire") || c.eq_ignore_ascii_case("smoke") || c == "明火" || c == "烟雾"))
                    || (alert.rule_id == "rule_falldown_sleep" && (c.eq_ignore_ascii_case("fall-down") || c.eq_ignore_ascii_case("sleeping") || c == "倒地" || c == "睡岗"))
                    || alert.rule_id.starts_with("rule_steel_")
                    || alert.rule_id.starts_with("rule_tile_")
                    || alert.rule_id.starts_with("rule_ppe_")
                    || alert.rule_id.starts_with("rule_yolo_")
                    || alert.rule_id.starts_with("rule_license_")
                    || alert.rule_id.starts_with("rule_plate_")
            })
        };

        for (idx, track) in tracked_objects.iter().enumerate() {
            let in_roi = in_roi_list[idx];
            let crossed = crossed_list[idx];
            if !in_roi && !crossed {
                continue;
            }

            let is_direct_target = class_in_targets(&zone_cfg.target_classes, track.label.as_deref(), track.class_id);

            if let Some(target_alerts) = alert_map.get(&track.track_id) {
                let mut triggered_any = false;
                for a in target_alerts {
                    let alert_allowed = rule_alert_allowed(a, &zone_cfg.target_classes);

                    if alert_allowed {
                        triggered_any = true;
                        let item_json = serde_json::json!({
                            "track_id": track.track_id,
                            "class_id": track.class_id,
                            "label": track.label,
                            "text": track.text,
                            "confidence": track.confidence,
                            "rel_box": track.rel_box,
                            "box": track.box_coord,
                            "center": track.center,
                            "trajectory": track.trajectory,
                            "hits": track.hits,
                            "age": track.age,
                            "in_roi": in_roi,
                            "crossed": crossed,
                            "triggered": true,
                            "rule_id": a.rule_id,
                            "rule_name": a.rule_name,
                            "alert_type": a.alert_type,
                            "detail": a.detail,
                        });
                        enriched_detections.push(item_json);
                    }
                }

                if !triggered_any {
                    if !is_direct_target && !zone_cfg.target_classes.is_empty() {
                        continue;
                    }
                    let triggered = is_direct_target;
                    let alert_type = if is_direct_target {
                        track.label.clone().unwrap_or_else(|| "person".to_string())
                    } else {
                        String::new()
                    };
                    let detail = if is_direct_target {
                        format!("检测到关注目标: {:?}", track.label)
                    } else {
                        String::new()
                    };

                    let item_json = serde_json::json!({
                        "track_id": track.track_id,
                        "class_id": track.class_id,
                        "label": track.label,
                        "text": track.text,
                        "confidence": track.confidence,
                        "rel_box": track.rel_box,
                        "box": track.box_coord,
                        "center": track.center,
                        "trajectory": track.trajectory,
                        "hits": track.hits,
                        "age": track.age,
                        "in_roi": in_roi,
                        "crossed": crossed,
                        "triggered": triggered,
                        "alert_type": alert_type,
                        "detail": detail,
                    });
                    enriched_detections.push(item_json);
                }
            } else if is_direct_target && !zone_cfg.target_classes.is_empty() {
                let item_json = serde_json::json!({
                    "track_id": track.track_id,
                    "class_id": track.class_id,
                    "label": track.label,
                    "text": track.text,
                    "confidence": track.confidence,
                    "rel_box": track.rel_box,
                    "box": track.box_coord,
                    "center": track.center,
                    "trajectory": track.trajectory,
                    "hits": track.hits,
                    "age": track.age,
                    "in_roi": in_roi,
                    "crossed": crossed,
                    "triggered": true,
                    "alert_type": track.label.clone().unwrap_or_else(|| "target_detected".to_string()),
                    "detail": format!("检测到关注目标: {:?}", track.label),
                });
                enriched_detections.push(item_json);
            } else {
                if !zone_cfg.target_classes.is_empty() {
                    continue;
                }
                let item_json = serde_json::json!({
                    "track_id": track.track_id,
                    "class_id": track.class_id,
                    "label": track.label,
                    "text": track.text,
                    "confidence": track.confidence,
                    "rel_box": track.rel_box,
                    "box": track.box_coord,
                    "center": track.center,
                    "trajectory": track.trajectory,
                    "hits": track.hits,
                    "age": track.age,
                    "in_roi": in_roi,
                    "crossed": crossed,
                    "triggered": false,
                });
                enriched_detections.push(item_json);
            }
        }

        for alert in alerts {
            if alert.track_id.is_none() {
                let allowed = rule_alert_allowed(&alert, &zone_cfg.target_classes);
                if allowed {
                    let item_json = serde_json::json!({
                        "track_id": null,
                        "class_id": alert.class_id,
                        "label": alert.label,
                        "confidence": alert.confidence,
                        "rel_box": alert.rel_box,
                        "box": alert.box_coord,
                        "center": alert.center,
                        "in_roi": true,
                        "crossed": false,
                        "triggered": true,
                        "rule_id": alert.rule_id,
                        "rule_name": alert.rule_name,
                        "alert_type": alert.alert_type,
                        "detail": alert.detail,
                    });
                    enriched_detections.push(item_json);
                }
            }
        }
    } else {
        for (idx, track) in tracked_objects.iter().enumerate() {
            let in_roi = in_roi_list[idx];
            let crossed = crossed_list[idx];

            let class_matched = if zone_cfg.target_classes.is_empty() {
                true
            } else {
                match (&track.label, track.class_id) {
                    (Some(label), _) => zone_cfg.target_classes.iter().any(|c| {
                        c.eq_ignore_ascii_case(label)
                            || (label.eq_ignore_ascii_case("person") && (c == "人员目标" || c.eq_ignore_ascii_case("person")))
                            || (label.eq_ignore_ascii_case("forklift") && (c == "工业搬运叉车" || c == "叉车" || c.eq_ignore_ascii_case("forklift")))
                            || (label.eq_ignore_ascii_case("hardhat") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("helmet")))
                            || (label.eq_ignore_ascii_case("helmet") && (c == "佩戴安全帽" || c.eq_ignore_ascii_case("hardhat")))
                            || (label.eq_ignore_ascii_case("no-hardhat") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-helmet")))
                            || (label.eq_ignore_ascii_case("no-helmet") && (c == "未戴安全帽" || c.eq_ignore_ascii_case("no-hardhat")))
                            || (label.eq_ignore_ascii_case("safety-vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("vest")))
                            || (label.eq_ignore_ascii_case("vest") && (c == "反光工作服" || c == "穿戴反光衣" || c.eq_ignore_ascii_case("safety-vest")))
                            || (label.eq_ignore_ascii_case("no-safety-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-vest")))
                            || (label.eq_ignore_ascii_case("no-vest") && (c == "未穿反光衣" || c.eq_ignore_ascii_case("no-safety-vest")))
                            || (label.eq_ignore_ascii_case("license_plate") && (c == "机动车车牌" || c == "车牌" || c.eq_ignore_ascii_case("plate") || c.eq_ignore_ascii_case("license_plate")))
                            || (label.eq_ignore_ascii_case("plate") && (c == "机动车车牌" || c == "车牌" || c.eq_ignore_ascii_case("plate") || c.eq_ignore_ascii_case("license_plate")))
                            || (label.eq_ignore_ascii_case("vehicle") && (c == "机动车辆" || c == "机动车" || c == "车辆" || c.eq_ignore_ascii_case("vehicle") || c.eq_ignore_ascii_case("car")))
                    }),
                    (None, Some(cid)) => {
                        let cid_str = cid.to_string();
                        zone_cfg.target_classes.iter().any(|c| c == &cid_str)
                    }
                    _ => false,
                }
            };

            let triggered = if !zone_cfg.enabled || !class_matched {
                false
            } else if crossed {
                true
            } else if zone_cfg.trigger_line.is_some() && zone_cfg.roi.is_none() {
                false
            } else {
                in_roi
            };

            if !triggered {
                continue;
            }

            let item_json = serde_json::json!({
                "track_id": track.track_id,
                "class_id": track.class_id,
                "label": track.label,
                "text": track.text,
                "confidence": track.confidence,
                "rel_box": track.rel_box,
                "box": track.box_coord,
                "center": track.center,
                "trajectory": track.trajectory,
                "hits": track.hits,
                "age": track.age,
                "in_roi": in_roi,
                "crossed": crossed,
                "triggered": triggered,
            });
            enriched_detections.push(item_json);
        }
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
    let text = obj
        .get("text")
        .or_else(|| obj.get("plate_text"))
        .and_then(|v| v.as_str())
        .map(|s| s.to_string());
    let confidence = obj.get("confidence").and_then(|v| v.as_f64()).unwrap_or(0.0);

    let mut rel_box = [0.0, 0.0, 0.0, 0.0];
    let mut box_coord = Vec::new();

    if let Some(r_arr) = obj.get("rel_box").and_then(|v| v.as_array()).filter(|a| a.len() >= 4) {
        rel_box[0] = r_arr[0].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
        rel_box[1] = r_arr[1].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
        rel_box[2] = r_arr[2].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
        rel_box[3] = r_arr[3].as_f64().unwrap_or(0.0).clamp(0.0, 1.0);
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
        text,
        confidence,
        rel_box,
        box_coord,
    })
}
