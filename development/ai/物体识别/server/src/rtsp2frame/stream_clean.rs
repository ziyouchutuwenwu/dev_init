use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use crate::detector::frame_detector::FrameDetector;

pub struct StreamCleanGuard {
    pub epoch: u64,
    pub running: Arc<AtomicBool>,
    pub detector: Option<Arc<FrameDetector>>,
}

impl Drop for StreamCleanGuard {
    fn drop(&mut self) {
        self.running.store(false, Ordering::Relaxed);
        if let Some(detector) = self.detector.take() {
            let _ = detector.release_channel();
            log::info!(
                "[rtsp_streamer:{}] rtsp 协程退出，已触发通道显存释放与检测线程终止",
                detector.stream_id()
            );
        }
    }
}
