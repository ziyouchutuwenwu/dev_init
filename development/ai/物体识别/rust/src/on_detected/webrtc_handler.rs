use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub struct WebRtcHandler;

impl WebRtcHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        tx_broadcast: broadcast::Sender<String>,
        latest_detection: Arc<RwLock<Option<String>>>,
    ) {
        tokio::spawn(loop_check(
            stream_id.into(),
            receiver,
            tx_broadcast,
            latest_detection,
        ));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    tx_broadcast: broadcast::Sender<String>,
    latest_detection: Arc<RwLock<Option<String>>>,
) {
    println!("[on_detected:webrtc:{stream_id}] WebRTC 订阅协程已启动");
    loop {
        match receiver.recv().await {
            Ok(result) => {
                if let Ok(json_msg) = serde_json::to_string(&*result) {
                    {
                        let mut cache = latest_detection.write().await;
                        *cache = Some(json_msg.clone());
                    }
                    let _ = tx_broadcast.send(json_msg);
                }
            }
            Err(broadcast::error::RecvError::Lagged(skipped)) => {
                log::warn!("[on_detected:webrtc:{stream_id}] 消费过慢，丢弃了 {skipped} 帧检测结果");
            }
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }
    println!("[on_detected:webrtc:{stream_id}] WebRTC 订阅协程已退出");
}
