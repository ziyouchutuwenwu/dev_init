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
                if let Some(ctx) = crate::on_detected::ObjectTrackHandler::get_context(&stream_id) {
                    let cfg = ctx.config.read().await;
                    if !cfg.enabled {
                        continue;
                    }
                }

                let triggered_detections: Vec<_> = result
                    .detections
                    .iter()
                    .filter(|d| {
                        let is_triggered = d.get("triggered")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(false);
                        let in_roi = d.get("in_roi")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(false);
                        let crossed = d.get("crossed")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(false);
                        is_triggered && (in_roi || crossed)
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

                let model_id = triggered_detections
                    .iter()
                    .find_map(|d| {
                        d.get("model_id")
                            .and_then(|v| v.as_str())
                            .map(|s| s.trim())
                            .filter(|s| !s.is_empty())
                            .map(|s| s.to_string())
                    })
                    .or_else(|| crate::config::channel::load_config(&stream_id).model)
                    .unwrap_or_default();

                let formatted_detections: Vec<serde_json::Value> = triggered_detections
                    .iter()
                    .map(|d| {
                        let label = d.get("label").and_then(|v| v.as_str()).unwrap_or("target");
                        let confidence = d
                            .get("confidence")
                            .and_then(|v| v.as_f64())
                            .map(|c| (c * 100.0).round() / 100.0)
                            .unwrap_or(0.0);
                        let box_coord: Vec<i64> = d
                            .get("box")
                            .or_else(|| d.get("box_coord"))
                            .and_then(|v| v.as_array())
                            .map(|arr| {
                                arr.iter()
                                    .filter_map(|x| x.as_f64().map(|f| f.round() as i64))
                                    .collect()
                            })
                            .unwrap_or_default();

                        let mut item = serde_json::json!({
                            "label": label,
                            "confidence": confidence,
                            "box": box_coord,
                        });

                        if let Some(text) = d
                            .get("text")
                            .or_else(|| d.get("plate_text"))
                            .and_then(|v| v.as_str())
                        {
                            if !text.is_empty() {
                                if let Some(item_obj) = item.as_object_mut() {
                                    item_obj.insert("text".to_string(), serde_json::json!(text));
                                }
                            }
                        }

                        item
                    })
                    .collect();

                let payload = serde_json::json!({
                    "stream_id": stream_id,
                    "timestamp": result.timestamp,
                    "model_id": model_id,
                    "detections": formatted_detections,
                })
                .to_string();

                log::info!(
                    "[http_post:{stream_id}] 触发【{model_id}】告警 (目标数: {}) -> {target_url}\n{payload}",
                    formatted_detections.len()
                );

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
                            log::warn!("[http_post:{stream_id_clone}] 发送告警到 {url_clone} 失败: {e}");
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
