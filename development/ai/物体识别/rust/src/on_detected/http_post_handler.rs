use crate::config::HttpPostRule;
use crate::detector::detection_result::DetectionResult;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;

const URL: &str = "http://127.0.0.1:4000/api/alert";
const TIMEOUT: Duration = Duration::from_secs(3);

pub struct HttpPostHandler;

pub type HttpHandler = HttpPostHandler;

impl HttpPostHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        rules: Option<HashMap<String, HttpPostRule>>,
    ) {
        tokio::spawn(loop_check(stream_id.into(), receiver, rules));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    rules: Option<HashMap<String, HttpPostRule>>,
) {
    let client = reqwest::Client::builder()
        .timeout(TIMEOUT)
        .build()
        .unwrap_or_default();

    loop {
        match receiver.recv().await {
            Ok(result) => {
                for detection in &result.detections {
                    let label = match detection.get("label") {
                        Some(serde_json::Value::String(s)) => s.clone(),
                        _ => continue,
                    };

                    let confidence = match detection.get("confidence") {
                        Some(serde_json::Value::Number(n)) => match n.as_f64() {
                            Some(v) => v,
                            None => 0.0,
                        },
                        _ => 0.0,
                    };

                    let url = match &rules {
                        Some(map) => match map.get(&label) {
                            Some(rule) => rule.url.clone(),
                            None => continue,
                        },
                        None => URL.to_string(),
                    };

                    log::info!(
                        "[http_post:{stream_id}] 触发 HTTP POST 信号! 类型: {label}, 地址(url): {url}, 置信度: {confidence:.2}"
                    );

                    let payload = serde_json::json!({
                        "stream_id": stream_id,
                        "label": label,
                        "confidence": confidence,
                        "timestamp": result.timestamp,
                        "detection": detection,
                    })
                    .to_string();

                    let client = client.clone();
                    tokio::spawn(async move {
                        let _ = client
                            .post(&url)
                            .header("Content-Type", "application/json")
                            .body(payload)
                            .send()
                            .await;
                    });
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => {}
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }
}
