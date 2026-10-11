use bytes::Bytes;
use rtc::media::Sample;
use std::sync::atomic::AtomicBool;
use std::sync::Arc;
use url::Url;
use crate::detector::frame_detector::FrameDetector;
use crate::on_detected::DetectedDispatcher;
use super::detector::spawn_detection;
use super::rtsp_client::run_rtsp_loop;
use super::stream_clean::StreamCleanGuard;
use super::vpu_feeder::spawn_vpu_feeder;

pub struct RtspStreamer {
    stream_id: String,
    rtsp_url: String,
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
}

impl RtspStreamer {
    pub fn new(
        stream_id: impl Into<String>,
        rtsp_url: impl Into<String>,
        detector: Arc<FrameDetector>,
        dispatcher: Arc<DetectedDispatcher>,
    ) -> Self {
        Self {
            stream_id: stream_id.into(),
            rtsp_url: rtsp_url.into(),
            detector,
            dispatcher,
        }
    }

    pub fn stream_id(&self) -> &str {
        &self.stream_id
    }

    pub async fn start_stream(
        &self,
        tx_video: tokio::sync::broadcast::Sender<Arc<Sample>>,
    ) -> Result<tokio::task::JoinHandle<()>, String> {
        let parsed_url = match Url::parse(&self.rtsp_url) {
            Ok(u) => u,
            Err(e) => return Err(format!("无效 rtsp url ({}): {e}", self.rtsp_url)),
        };

        let (vpu_feed_tx, vpu_feed_rx) =
            tokio::sync::mpsc::channel::<(Bytes, u64, i64, u64)>(64);

        let running = Arc::new(AtomicBool::new(true));

        spawn_vpu_feeder(vpu_feed_rx, Arc::clone(&self.detector), Arc::clone(&running));
        spawn_detection(Arc::clone(&self.detector), Arc::clone(&self.dispatcher), Arc::clone(&running));

        let running_cleanup = Arc::clone(&running);
        let detector_cleanup = Arc::clone(&self.detector);
        let stream_id = self.stream_id.clone();
        let detector = Arc::clone(&self.detector);

        let session_epoch = self.detector.next_session_epoch();
        let handle = tokio::spawn(async move {
            let _guard = StreamCleanGuard {
                epoch: session_epoch,
                running: running_cleanup,
                detector: detector_cleanup,
            };
            run_rtsp_loop(
                stream_id,
                parsed_url,
                detector,
                tx_video,
                vpu_feed_tx,
            ).await;
        });

        Ok(handle)
    }
}
