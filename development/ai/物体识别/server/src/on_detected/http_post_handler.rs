use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;

pub const ALERT_URL: &str = "http://127.0.0.1:4000/api/alert";

const TIMEOUT: Duration = Duration::from_secs(3);
const COOLDOWN: Duration = Duration::from_millis(1500);

pub struct HttpPostHandler;

pub type HttpHandler = HttpPostHandler;

impl HttpPostHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
    ) {
        let stream_id = stream_id.into();
        log::info!("[http_post:{stream_id}] HttpPostHandler 已成功启动，硬编码告警目标: {ALERT_URL}");
        tokio::spawn(loop_check(stream_id, receiver));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
) {
    let client = reqwest::Client::builder()
        .timeout(TIMEOUT)
        .build()
        .unwrap_or_default();

    let mut last_post_time = std::time::Instant::now()
        .checked_sub(COOLDOWN)
        .unwrap_or_else(std::time::Instant::now);

    loop {
        match receiver.recv().await {
            Ok(result) => {
                if result.detections.is_empty() {
                    continue;
                }

                if last_post_time.elapsed() < COOLDOWN {
                    continue;
                }

                last_post_time = std::time::Instant::now();

                log::info!(
                    "[http_post:{stream_id}] 检测到目标 (数量: {})，触发 HTTP POST 告警 -> {ALERT_URL}",
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
                })
                .to_string();

                let client = client.clone();
                let stream_id_clone = stream_id.clone();
                tokio::spawn(async move {
                    match client
                        .post(ALERT_URL)
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
                            log::warn!("[http_post:{stream_id_clone}] 发送告警到 {ALERT_URL} 失败: {e}");
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
