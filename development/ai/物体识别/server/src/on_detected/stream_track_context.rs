use crate::object_tracker::{ObjectTracker, ZoneConfig};
use std::sync::{Arc, Mutex};
use tokio::sync::RwLock;

pub struct StreamTrackContext {
    pub stream_id: String,
    pub config: Arc<RwLock<ZoneConfig>>,
    pub tracker: Arc<Mutex<ObjectTracker>>,
}

impl StreamTrackContext {
    pub fn new(stream_id: &str, initial_config: ZoneConfig) -> Self {
        Self {
            stream_id: stream_id.to_string(),
            config: Arc::new(RwLock::new(initial_config)),
            tracker: Arc::new(Mutex::new(ObjectTracker::new())),
        }
    }
}
