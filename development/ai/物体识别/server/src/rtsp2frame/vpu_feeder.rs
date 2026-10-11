use bytes::Bytes;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use crate::detector::frame_detector::FrameDetector;

pub fn spawn_vpu_feeder(
    rx: tokio::sync::mpsc::Receiver<(Bytes, u64, i64, u64)>,
    detector: Arc<FrameDetector>,
    running: Arc<AtomicBool>,
) {
    tokio::task::spawn_blocking(move || run_vpu_feeder(rx, detector, running));
}

fn run_vpu_feeder(
    mut rx: tokio::sync::mpsc::Receiver<(Bytes, u64, i64, u64)>,
    detector: Arc<FrameDetector>,
    running: Arc<AtomicBool>,
) {
    while running.load(Ordering::Relaxed) {
        match rx.blocking_recv() {
            Some((nal_data, seq, pts, epoch)) => {
                if epoch != detector.flush_epoch() {
                    continue;
                }
                let _ = detector.feed_packet(&nal_data, seq, pts);
            }
            None => break,
        }
    }
}
