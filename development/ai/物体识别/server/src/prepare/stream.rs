use crate::config::StreamConfig;
use crate::detector::{DetectWrapper, FrameDetector};
use crate::on_detected::{
    DetectedDispatcher, HttpPostHandler, ObjectTrackHandler, WebRtcHandler,
};
use crate::rtsp2frame::RtspStreamer;
use crate::object_tracker::ZoneConfig;
use crate::web_rtc::StreamContext;
use std::sync::Arc;
use tokio::sync::broadcast;

pub fn init_detector(_total_streams: usize) -> Arc<DetectWrapper> {
    let detect_wrapper = Arc::new(DetectWrapper::new());
    match detect_wrapper.init_engine() {
        Ok(()) => {
            log::info!("[server] 算法引擎连接就绪，模型加载成功");
        }
        Err(e) => {
            log::error!("[server] 算法引擎初始化失败: {e}");
        }
    }
    detect_wrapper
}

pub async fn setup_single_stream(
    ch_idx: u32,
    stream_cfg: StreamConfig,
    detect_wrapper: Arc<DetectWrapper>,
) -> Result<(StreamContext, tokio::task::JoinHandle<()>), Box<dyn std::error::Error>> {
    let stream_id = stream_cfg.id;
    let input_url = stream_cfg.input;
    let (tx_detection, _rx) = broadcast::channel::<String>(64);
    let latest_detection = Arc::new(tokio::sync::RwLock::new(None));

    let detector = Arc::new(FrameDetector::with_channel(
        detect_wrapper,
        ch_idx,
        stream_id.clone(),
    ));

    if let Err(e) = detector.create_channel() {
        eprintln!("[server:{stream_id}] warning: create_channel (ch={ch_idx}) failed: {e}");
    }

    let stream_ctx = StreamContext::new(
        stream_id.clone(),
        input_url.clone(),
        tx_detection.clone(),
        Arc::clone(&latest_detection),
    );

    let raw_dispatcher = Arc::new(DetectedDispatcher::new());
    let processed_dispatcher = Arc::new(DetectedDispatcher::new());

    let config_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
    let initial_zone_cfg = ZoneConfig::load_from_yaml_file(&config_path, &stream_id);
    ObjectTrackHandler::start(
        &stream_id,
        raw_dispatcher.subscribe(),
        Arc::clone(&processed_dispatcher),
        initial_zone_cfg,
    );

    WebRtcHandler::start(
        &stream_id,
        processed_dispatcher.subscribe(),
        tx_detection,
        Arc::clone(&latest_detection),
    );
    HttpPostHandler::start(&stream_id, processed_dispatcher.subscribe());

    let streamer = RtspStreamer::new(
        stream_id.clone(),
        input_url.clone(),
        detector,
        raw_dispatcher,
    );

    let handle = streamer.start_stream(stream_ctx.tx_video.clone()).await?;
    Ok((stream_ctx, handle))
}

pub async fn start_initial_streams(
    streams: Vec<StreamConfig>,
    detect_wrapper: Arc<DetectWrapper>,
) -> Result<Vec<crate::web_rtc::RunningStream>, Box<dyn std::error::Error>> {
    let mut running = Vec::new();

    for (ch_idx, st) in streams.into_iter().enumerate() {
        let stream_id = st.id.clone();
        let input_url = st.input.clone();
        let (ctx, handle) = setup_single_stream(
            ch_idx as u32,
            st,
            Arc::clone(&detect_wrapper),
        )
        .await?;
        running.push(crate::web_rtc::RunningStream {
            stream_id,
            input_url,
            channel_id: ch_idx as u32,
            context: ctx,
            handle,
        });
    }

    Ok(running)
}

pub async fn start_all_streams(
    streams: Vec<StreamConfig>,
    detect_wrapper: Arc<DetectWrapper>,
) -> Result<(Vec<StreamContext>, Vec<tokio::task::JoinHandle<()>>), Box<dyn std::error::Error>> {
    let mut stream_contexts = Vec::new();
    let mut streamer_handles = Vec::new();

    for (ch_idx, st) in streams.into_iter().enumerate() {
        let (ctx, handle) = setup_single_stream(
            ch_idx as u32,
            st,
            Arc::clone(&detect_wrapper),
        )
        .await?;
        stream_contexts.push(ctx);
        streamer_handles.push(handle);
    }

    Ok((stream_contexts, streamer_handles))
}
