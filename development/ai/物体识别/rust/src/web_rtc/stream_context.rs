use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use webrtc::rtp_transceiver::rtp_codec::RTCRtpCodecCapability;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

#[derive(Clone)]
pub struct StreamContext {
    pub stream_id: String,
    pub input_url: String,
    pub video_track: Arc<TrackLocalStaticSample>,
    pub tx_detection: broadcast::Sender<String>,
    pub latest_detection: Arc<RwLock<Option<String>>>,
}

impl StreamContext {
    pub fn create_video_track(stream_id: &str) -> Arc<TrackLocalStaticSample> {
        Arc::new(TrackLocalStaticSample::new(
            RTCRtpCodecCapability {
                mime_type: "video/H264".to_owned(),
                clock_rate: 90000,
                channels: 0,
                sdp_fmtp_line: "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f".to_owned(),
                rtcp_feedback: vec![],
            },
            format!("video_{}", stream_id),
            format!("rtsp-stream-{}", stream_id),
        ))
    }
}
