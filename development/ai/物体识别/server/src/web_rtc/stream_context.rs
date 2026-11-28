use rtc::media::Sample;
use rtc::media_stream::MediaStreamTrack;
use rtc::rtp_transceiver::rtp_sender::{
    RTCRtpCodec, RTCRtpCodingParameters, RTCRtpEncodingParameters, RtpCodecKind,
};
use rtc::rtp_transceiver::PayloadType;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use webrtc::media_stream::track_local::static_sample::TrackLocalStaticSample;

#[derive(Clone)]
pub struct StreamContext {
    pub stream_id: String,
    pub input_url: String,
    pub tx_video: broadcast::Sender<Arc<Sample>>,
    pub tx_detection: broadcast::Sender<String>,
    pub latest_detection: Arc<RwLock<Option<String>>>,
    pub video_encoding: Arc<RwLock<String>>,
}

impl StreamContext {
    pub fn new(
        stream_id: impl Into<String>,
        input_url: impl Into<String>,
        tx_detection: broadcast::Sender<String>,
        latest_detection: Arc<RwLock<Option<String>>>,
    ) -> Self {
        let (tx_video, _) = broadcast::channel::<Arc<Sample>>(48);
        Self {
            stream_id: stream_id.into(),
            input_url: input_url.into(),
            tx_video,
            tx_detection,
            latest_detection,
            video_encoding: Arc::new(RwLock::new("h264".to_string())),
        }
    }

    pub fn create_video_track_with_mime(
        stream_id: &str,
        mime_type: &str,
    ) -> Result<(Arc<TrackLocalStaticSample>, u32, PayloadType), webrtc::error::Error> {
        static NEXT_SSRC: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(10001);
        let ssrc = NEXT_SSRC.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        let is_h265 = mime_type.eq_ignore_ascii_case("video/H265")
            || mime_type.eq_ignore_ascii_case("video/HEVC")
            || mime_type.eq_ignore_ascii_case("h265")
            || mime_type.eq_ignore_ascii_case("hevc");
        let (payload_type, chosen_mime, sdp_fmtp_line) = if is_h265 {
            (104, "video/H265".to_string(), "".to_string())
        } else {
            (
                102,
                "video/H264".to_string(),
                "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f".to_string(),
            )
        };
        let codec = RTCRtpCodec {
            mime_type: chosen_mime,
            clock_rate: 90000,
            channels: 0,
            sdp_fmtp_line,
            rtcp_feedback: vec![],
        };

        let track = Arc::new(TrackLocalStaticSample::new(MediaStreamTrack::new(
            format!("video_{stream_id}"),
            format!("rtsp-stream-{stream_id}"),
            format!("video_{stream_id}"),
            RtpCodecKind::Video,
            vec![RTCRtpEncodingParameters {
                rtp_coding_parameters: RTCRtpCodingParameters {
                    ssrc: Some(ssrc),
                    ..Default::default()
                },
                codec,
                ..Default::default()
            }],
        ))?);

        Ok((track, ssrc, payload_type))
    }

    pub fn create_video_track(
        stream_id: &str,
    ) -> Result<(Arc<TrackLocalStaticSample>, u32, PayloadType), webrtc::error::Error> {
        Self::create_video_track_with_mime(stream_id, "video/H264")
    }
}
