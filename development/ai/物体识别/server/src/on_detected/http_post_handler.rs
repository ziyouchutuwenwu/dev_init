use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;

static CURRENT_ALERT_URL: std::sync::RwLock<Option<String>> = std::sync::RwLock::new(None);
static CURRENT_ALERT_COOLDOWN_SEC: std::sync::RwLock<Option<u64>> = std::sync::RwLock::new(None);
static CURRENT_ALERT_TIMEOUT_SEC: std::sync::RwLock<Option<u64>> = std::sync::RwLock::new(None);

pub fn get_alert_url() -> String {
    if let Ok(guard) = CURRENT_ALERT_URL.read()
        && let Some(ref url) = *guard
    {
        return url.clone();
    }
    String::new()
}

pub fn set_alert_url(url: impl Into<String>) {
    let u = url.into().trim().to_string();
    if let Ok(mut guard) = CURRENT_ALERT_URL.write() {
        *guard = Some(u);
    }
}

pub fn get_alert_cooldown_sec() -> Option<u64> {
    if let Ok(guard) = CURRENT_ALERT_COOLDOWN_SEC.read() {
        return *guard;
    }
    None
}

pub fn set_alert_cooldown_sec(sec: Option<u64>) {
    if let Ok(mut guard) = CURRENT_ALERT_COOLDOWN_SEC.write() {
        *guard = sec;
    }
}

pub fn get_alert_timeout_sec() -> Option<u64> {
    if let Ok(guard) = CURRENT_ALERT_TIMEOUT_SEC.read() {
        return *guard;
    }
    None
}

pub fn set_alert_timeout_sec(sec: Option<u64>) {
    if let Ok(mut guard) = CURRENT_ALERT_TIMEOUT_SEC.write() {
        *guard = sec;
    }
}

pub struct HttpPostHandler;

pub type HttpHandler = HttpPostHandler;

impl HttpPostHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
    ) {
        let stream_id = stream_id.into();
        let target = get_alert_url();
        if target.is_empty() {
            log::info!("[http_post:{stream_id}] httpposthandler 已成功启动 (当前未配置告警目标)");
        } else {
            log::info!("[http_post:{stream_id}] httpposthandler 已成功启动，当前告警目标: {target}");
        }
        tokio::spawn(loop_check(stream_id, receiver));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
) {
    let client = reqwest::Client::builder()
        .build()
        .unwrap_or_default();

    let mut last_post_time: Option<std::time::Instant> = None;

    loop {
        match receiver.recv().await {
            Ok(result) => {
                if !crate::web_rtc::is_stream_connected(&stream_id) {
                    continue;
                }

                let is_zone_enabled = result
                    .zone_config
                    .as_ref()
                    .and_then(|z| z.get("enabled"))
                    .and_then(|e| e.as_bool())
                    .unwrap_or(true);

                if !is_zone_enabled {
                    continue;
                }

                let triggered_detections: Vec<_> = result
                    .detections
                    .iter()
                    .filter(|d| {
                        d.get("triggered")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(true)
                    })
                    .cloned()
                    .collect();

                if triggered_detections.is_empty() {
                    continue;
                }

                let target_url = get_alert_url();
                if target_url.trim().is_empty() {
                    continue;
                }

                if let Some(cooldown_sec) = get_alert_cooldown_sec() {
                    let cooldown = Duration::from_secs(cooldown_sec);
                    if let Some(last_time) = last_post_time
                        && last_time.elapsed() < cooldown
                    {
                        continue;
                    }
                }

                last_post_time = Some(std::time::Instant::now());

                let model = result
                    .zone_config
                    .as_ref()
                    .and_then(|z| z.get("model"))
                    .and_then(|m| m.as_str())
                    .unwrap_or("industry")
                    .to_string();

                let model_name = match model.as_str() {
                    "industry" => "工业检测",
                    "safety_ppe" => "穿戴检测",
                    "forklift_collision" => "叉车防撞",
                    "steel_defect" => "钢材缺陷检测",
                    "tile_defect" => "瓷砖缺陷检测",
                    "yolo_raw" => "通用检测",
                    "license_plate" => "车牌识别",
                    other => other,
                };

                let event_id = format!("evt_{}_{}", result.timestamp, stream_id);

                let first_alert = triggered_detections
                    .iter()
                    .find_map(|d| d.get("alert_type").or_else(|| d.get("rule_name")).and_then(|v| v.as_str()));

                let alert_type = match first_alert {
                    Some(at) => at.to_string(),
                    None => {
                        if model == "license_plate" {
                            "license_plate_recognized".to_string()
                        } else {
                            "target_detected".to_string()
                        }
                    }
                };

                let detected_labels: Vec<&str> = triggered_detections
                    .iter()
                    .filter_map(|d| d.get("label").and_then(|v| v.as_str()))
                    .collect();
                let mut unique_labels = detected_labels.clone();
                unique_labels.dedup();
                let labels_summary = if unique_labels.is_empty() {
                    "目标".to_string()
                } else {
                    unique_labels.join(", ")
                };

                let alert_name = if model == "license_plate" {
                    let plate_txt = triggered_detections.iter().find_map(|d| {
                        d.get("text").or_else(|| d.get("plate_text")).and_then(|v| v.as_str())
                    });
                    match plate_txt {
                        Some(txt) if !txt.is_empty() => format!("车牌识别: {}", txt),
                        _ => "识别到机动车车牌".to_string(),
                    }
                } else if model == "yolo_raw" {
                    format!("通用检测: {}", labels_summary)
                } else if let Some(rule) = first_alert {
                    if rule.contains("出入") || rule.contains("通用") || rule.is_empty() {
                        format!("检测到: {}", labels_summary)
                    } else if !labels_summary.is_empty() && !rule.contains(&labels_summary) {
                        format!("{}: {}", rule, labels_summary)
                    } else {
                        rule.to_string()
                    }
                } else {
                    format!("检测到: {}", labels_summary)
                };

                let alert_level = if alert_name.contains("预警")
                    || alert_name.contains("未戴")
                    || alert_name.contains("未穿")
                    || alert_name.contains("缺陷")
                    || alert_name.contains("火")
                    || alert_name.contains("烟")
                {
                    "warning"
                } else {
                    "info"
                };

                let formatted_detections: Vec<serde_json::Value> = triggered_detections
                    .iter()
                    .map(|d| {
                        let track_id = d.get("track_id").cloned().unwrap_or(serde_json::Value::Null);
                        let label = d.get("label").and_then(|v| v.as_str()).unwrap_or("target");
                        let class_id = d.get("class_id").cloned().unwrap_or(serde_json::Value::Null);
                        let confidence = d.get("confidence").and_then(|v| v.as_f64()).unwrap_or(0.0);
                        let box_coord = d
                            .get("box")
                            .or_else(|| d.get("box_coord"))
                            .cloned()
                            .unwrap_or(serde_json::json!([]));
                        let rel_box = d.get("rel_box").cloned().unwrap_or(serde_json::json!([]));

                        let mut extra = serde_json::Map::new();
                        if let Some(text) = d
                            .get("text")
                            .or_else(|| d.get("plate_text"))
                            .and_then(|v| v.as_str())
                        {
                            if !text.is_empty() {
                                extra.insert("plate_text".to_string(), serde_json::json!(text));
                            }
                        }
                        if let Some(rule_id) = d.get("rule_id").and_then(|v| v.as_str()) {
                            extra.insert("rule_id".to_string(), serde_json::json!(rule_id));
                        }
                        if let Some(rule_name) = d.get("rule_name").and_then(|v| v.as_str()) {
                            extra.insert("rule_name".to_string(), serde_json::json!(rule_name));
                        }
                        if let Some(detail) = d.get("detail").and_then(|v| v.as_str()) {
                            extra.insert("detail".to_string(), serde_json::json!(detail));
                        }

                        let mut item = serde_json::json!({
                            "track_id": track_id,
                            "class": label,
                            "class_id": class_id,
                            "label": label,
                            "name": label,
                            "confidence": confidence,
                            "box": box_coord,
                            "rel_box": rel_box,
                            "extra": extra,
                        });

                        if let Some(obj) = d.as_object() {
                            if let Some(item_obj) = item.as_object_mut() {
                                for (k, v) in obj {
                                    if !item_obj.contains_key(k) {
                                        item_obj.insert(k.clone(), v.clone());
                                    }
                                }
                            }
                        }
                        item
                    })
                    .collect();

                log::info!(
                    "[http_post:{stream_id}] 触发【{}】告警 (类型: {}, 目标数: {}) -> {target_url}",
                    model_name,
                    alert_name,
                    formatted_detections.len()
                );

                let payload = serde_json::json!({
                    "event_id": event_id,
                    "timestamp": result.timestamp,
                    "stream_id": stream_id,
                    "model": model,
                    "model_name": model_name,
                    "alert_type": alert_type,
                    "alert_name": alert_name,
                    "alert_level": alert_level,
                    "frame_info": {
                        "width": result.frame_width.unwrap_or(1920),
                        "height": result.frame_height.unwrap_or(1080),
                        "frame_idx": result.frame_idx,
                        "pts_ms": result.pts_ms,
                    },
                    "detections": formatted_detections,
                    "frame_idx": result.frame_idx,
                    "pts_ms": result.pts_ms,
                    "frame_width": result.frame_width,
                    "frame_height": result.frame_height,
                    "zone_config": result.zone_config,
                })
                .to_string();

                let timeout_duration = get_alert_timeout_sec()
                    .map(Duration::from_secs)
                    .unwrap_or(Duration::from_secs(3));

                let client = client.clone();
                let stream_id_clone = stream_id.clone();
                let url_clone = target_url.clone();
                tokio::spawn(async move {
                    match client
                        .post(&url_clone)
                        .timeout(timeout_duration)
                        .header("Content-Type", "application/json")
                        .body(payload)
                        .send()
                        .await
                    {
                        Ok(resp) => {
                            if resp.status().is_success() {
                                log::info!("[http_post:{stream_id_clone}] 告警推送成功 (status={})", resp.status());
                            } else {
                                log::warn!("[http_post:{stream_id_clone}] 告警推送返回异常状态: {}", resp.status());
                            }
                        }
                        Err(e) => {
                            static FAILED_COUNT: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
                            let count = FAILED_COUNT.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                            if count == 0 || count.is_multiple_of(30) {
                                log::warn!("[http_post:{stream_id_clone}] 发送告警到 {url_clone} 失败 (连续第 {count} 次): {e}");
                            }
                        }
                    }
                });
            }
            Err(broadcast::error::RecvError::Lagged(_)) => {}
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }
}
