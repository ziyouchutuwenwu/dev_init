use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use crate::detector::frame_detector::FrameDetector;
use crate::on_detected::DetectedDispatcher;

pub fn spawn_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
    running: Arc<AtomicBool>,
) {
    tokio::task::spawn_blocking(move || run_detection(detector, dispatcher, running));
}

fn run_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
    running: Arc<AtomicBool>,
) {
    let mut last_processed_seq: Option<u64> = None;
    let mut last_detect_time = std::time::Instant::now();
    let mut last_epoch = detector.flush_epoch();

    while running.load(Ordering::Relaxed) {
        let cur_epoch = detector.flush_epoch();
        if cur_epoch != last_epoch {
            last_epoch = cur_epoch;
            last_processed_seq = None;
        }

        let elapsed = last_detect_time.elapsed();
        if elapsed < Duration::from_millis(50) {
            std::thread::sleep(Duration::from_millis(50) - elapsed);
        }
        match detector.detect_latest() {
            Ok(Some(det_result)) => {
                let cur_seq = det_result.frame_idx;
                if cur_seq.is_some() && cur_seq != last_processed_seq {
                    last_processed_seq = cur_seq;
                    last_detect_time = std::time::Instant::now();
                    dispatcher.publish(Arc::new(det_result));
                } else {
                    std::thread::sleep(Duration::from_millis(10));
                }
            }
            Ok(None) => {
                std::thread::sleep(Duration::from_millis(12));
            }
            Err(_) => {
                std::thread::sleep(Duration::from_millis(20));
            }
        }
    }
    log::info!("[detection:{}] 检测后台线程已安全退出", detector.stream_id());
}
