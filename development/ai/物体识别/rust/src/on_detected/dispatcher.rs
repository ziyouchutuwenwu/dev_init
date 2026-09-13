use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct DetectedDispatcher {
    sender: broadcast::Sender<Arc<DetectionResult>>,
}

impl DetectedDispatcher {
    pub fn new() -> Self {
        Self::with_capacity(128)
    }

    pub fn with_capacity(capacity: usize) -> Self {
        let (sender, _) = broadcast::channel(capacity);
        Self { sender }
    }

    pub fn subscribe(&self) -> broadcast::Receiver<Arc<DetectionResult>> {
        self.sender.subscribe()
    }

    pub fn publish(&self, result: Arc<DetectionResult>) {
        let _ = self.sender.send(result);
    }
}

impl Default for DetectedDispatcher {
    fn default() -> Self {
        Self::new()
    }
}