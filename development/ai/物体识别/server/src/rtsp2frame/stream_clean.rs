use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use crate::detector::frame_detector::FrameDetector;

pub struct StreamCleanGuard {
    pub epoch: u64,
    pub running: Arc<AtomicBool>,
    pub detector: Arc<FrameDetector>,
}

impl Drop for StreamCleanGuard {
    fn drop(&mut self) {
        self.running.store(false, Ordering::Relaxed);
        let detector = Arc::clone(&self.detector);
        let my_epoch = self.epoch;
        if let Ok(handle) = tokio::runtime::Handle::try_current() {
            handle.spawn(async move {
                tokio::time::sleep(Duration::from_millis(500)).await;
                if detector.session_epoch() == my_epoch {
                    let _ = detector.release_channel();
                    log::info!(
                        "[rtsp_streamer:{}] rtsp 主循环退出，已触发通道显存释放与检测线程终止",
                        detector.stream_id()
                    );
                } else {
                    log::info!(
                        "[rtsp_streamer:{}] 忽略旧会话的延迟释放 (epoch: {} != {})",
                        detector.stream_id(),
                        my_epoch,
                        detector.session_epoch()
                    );
                }
            });
        } else {
            let _ = detector.release_channel();
        }
    }
}
