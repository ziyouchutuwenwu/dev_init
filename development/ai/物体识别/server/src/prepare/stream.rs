use crate::config::StreamConfig;
use crate::detector::{DetectWrapper, FrameDetector};
use crate::on_detected::{DetectedDispatcher, HttpPostHandler, WebRtcHandler};
use crate::rtsp2frame::RtspStreamer;
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

    let dispatcher = Arc::new(DetectedDispatcher::new());
    WebRtcHandler::start(
        &stream_id,
        dispatcher.subscribe(),
        tx_detection,
        Arc::clone(&latest_detection),
    );
    HttpPostHandler::start(&stream_id, dispatcher.subscribe());

    let streamer = RtspStreamer::new(
        stream_id.clone(),
        input_url.clone(),
        detector,
        dispatcher,
    );

    let handle = streamer.start_stream(stream_ctx.tx_video.clone()).await?;
    Ok((stream_ctx, handle))
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
