use crate::config::{ModbusRule, StreamConfig};
use crate::detector::{DetectCWrapper, FrameDetector};
use crate::on_detected::{DetectedDispatcher, ModbusHandler, WebRtcHandler};
use crate::rtsp2frame::RtspStreamer;
use crate::web_rtc::{StreamContext, WebRtcServer};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::broadcast;

pub fn init_detector(total_streams: usize) -> Arc<DetectCWrapper> {
    let detect_wrapper = Arc::new(DetectCWrapper::new());
    if let Err(e) = detect_wrapper.init(total_streams as u32) {
        eprintln!("[server] warning: init failed: {e}");
    }
    detect_wrapper
}

pub async fn setup_single_stream(
    ch_idx: u32,
    stream_cfg: StreamConfig,
    detect_wrapper: Arc<DetectCWrapper>,
    modbus_rules: Option<HashMap<String, ModbusRule>>,
) -> Result<(StreamContext, tokio::task::JoinHandle<()>), Box<dyn std::error::Error>> {
    let stream_id = stream_cfg.id;
    let input_url = stream_cfg.input;
    let (tx_detection, _rx) = broadcast::channel::<String>(256);
    let latest_detection = Arc::new(tokio::sync::RwLock::new(None));

    let detector = Arc::new(FrameDetector::with_channel(
        detect_wrapper,
        ch_idx,
        stream_id.clone(),
    ));

    let video_track = WebRtcServer::create_video_track(&stream_id);

    let stream_ctx = StreamContext {
        stream_id: stream_id.clone(),
        input_url: input_url.clone(),
        video_track: Arc::clone(&video_track),
        tx_detection: tx_detection.clone(),
        latest_detection: Arc::clone(&latest_detection),
    };

    let dispatcher = Arc::new(DetectedDispatcher::new());
    WebRtcHandler::start(
        &stream_id,
        dispatcher.subscribe(),
        tx_detection,
        Arc::clone(&latest_detection),
    );
    ModbusHandler::start(&stream_id, dispatcher.subscribe(), modbus_rules);

    let streamer = RtspStreamer::new(
        stream_id.clone(),
        input_url.clone(),
        detector,
        dispatcher,
    );

    let handle = streamer.start_stream(video_track).await?;
    Ok((stream_ctx, handle))
}

pub async fn start_all_streams(
    streams: Vec<StreamConfig>,
    detect_wrapper: Arc<DetectCWrapper>,
    modbus_rules: Option<HashMap<String, ModbusRule>>,
) -> Result<(Vec<StreamContext>, Vec<tokio::task::JoinHandle<()>>), Box<dyn std::error::Error>> {
    let mut stream_contexts = Vec::new();
    let mut streamer_handles = Vec::new();

    for (ch_idx, st) in streams.into_iter().enumerate() {
        let (ctx, handle) = setup_single_stream(
            ch_idx as u32,
            st,
            Arc::clone(&detect_wrapper),
            modbus_rules.clone(),
        )
        .await?;
        stream_contexts.push(ctx);
        streamer_handles.push(handle);
    }

    Ok((stream_contexts, streamer_handles))
}
