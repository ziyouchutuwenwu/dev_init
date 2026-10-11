use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;

static CURRENT_ALERT_URL: std::sync::RwLock<Option<String>> = std::sync::RwLock::new(None);
static CURRENT_ALERT_COOLDOWN_SEC: std::sync::RwLock<Option<u64>> = std::sync::RwLock::new(None);
static CURRENT_ALERT_TIMEOUT_SEC: std::sync::RwLock<Option<u64>> = std::sync::RwLock::new(None);

pub fn get_alert_url() -> String {
    if let Ok(guard) = CURRENT_ALERT_URL.read() {
        if let Some(ref url) = *guard {
            return url.clone();
        }
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
                if result.detections.is_empty() {
                    continue;
                }

                let target_url = get_alert_url();
                if target_url.trim().is_empty() {
                    continue;
                }

                if let Some(cooldown_sec) = get_alert_cooldown_sec() {
                    let cooldown = Duration::from_secs(cooldown_sec);
                    if let Some(last_time) = last_post_time {
                        if last_time.elapsed() < cooldown {
                            continue;
                        }
                    }
                }

                last_post_time = Some(std::time::Instant::now());

                log::info!(
                    "[http_post:{stream_id}] 检测到目标 (数量: {})，触发 http post 告警 -> {target_url}",
                    result.detections.len()
                );

                let payload = serde_json::json!({
                    "stream_id": stream_id,
                    "timestamp": result.timestamp,
                    "frame_idx": result.frame_idx,
                    "pts_ms": result.pts_ms,
                    "frame_width": result.frame_width,
                    "frame_height": result.frame_height,
                    "detections": result.detections,
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
                            if count == 0 || count % 30 == 0 {
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
