use bytes::Bytes;
use futures::StreamExt;
use retina::client::{Demuxed, PlayOptions, Session, SessionOptions, SetupOptions};
use retina::codec::{CodecItem, FrameFormat};
use std::sync::Arc;
use std::time::Duration;
use url::Url;
use webrtc::media::Sample;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;
use super::h264_utils::H264Utils;
use crate::detector::frame_detector::FrameDetector;
use crate::on_detected::DetectedDispatcher;

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
        track: Arc<TrackLocalStaticSample>,
    ) -> Result<tokio::task::JoinHandle<()>, String> {
        let parsed_url = match Url::parse(&self.rtsp_url) {
            Ok(u) => u,
            Err(e) => return Err(format!("无效 RTSP URL ({}): {e}", self.rtsp_url)),
        };

        let (vpu_feed_tx, vpu_feed_rx) =
            tokio::sync::mpsc::channel::<(Vec<u8>, u64, i64)>(256);

        spawn_vpu_feeder(vpu_feed_rx, Arc::clone(&self.detector));
        spawn_detection(Arc::clone(&self.detector), Arc::clone(&self.dispatcher));

        let handle = tokio::spawn(run_rtsp_loop(
            self.stream_id.clone(),
            parsed_url,
            Arc::clone(&self.detector),
            track,
            vpu_feed_tx,
        ));

        Ok(handle)
    }
}

fn spawn_vpu_feeder(
    rx: tokio::sync::mpsc::Receiver<(Vec<u8>, u64, i64)>,
    detector: Arc<FrameDetector>,
) {
    tokio::task::spawn_blocking(move || run_vpu_feeder(rx, detector));
}

fn spawn_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
) {
    tokio::task::spawn_blocking(move || run_detection(detector, dispatcher));
}

async fn run_rtsp_loop(
    stream_id: String,
    parsed_url: Url,
    detector: Arc<FrameDetector>,
    track: Arc<TrackLocalStaticSample>,
    vpu_feed_tx: tokio::sync::mpsc::Sender<(Vec<u8>, u64, i64)>,
) {
    loop {
        let session_options =
            SessionOptions::default().user_agent("rtsp-webrtc-streamer/1.0".to_owned());

        let session_res =
            Session::describe(parsed_url.clone(), session_options).await;

        let mut session = match session_res {
            Ok(s) => s,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] describe 失败: {e}，2秒后重试");
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut stream_idx = None;
        for (idx, s) in session.streams().iter().enumerate() {
            if s.media() == "video" {
                stream_idx = Some(idx);
                break;
            }
        }

        let stream_idx = match stream_idx {
            Some(idx) => idx,
            None => {
                eprintln!("[rtsp:{stream_id}] 未在 rtsp 中找到视频轨，2秒后重试");
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let setup_opts = SetupOptions::default().frame_format(FrameFormat::SIMPLE);
        if let Err(e) = session.setup(stream_idx, setup_opts).await {
            eprintln!("[rtsp:{stream_id}] setup 失败: {e}，2秒后重试");
            tokio::time::sleep(Duration::from_secs(2)).await;
            continue;
        }

        if let Some(retina::codec::ParametersRef::Video(v)) =
            session.streams()[stream_idx].parameters()
        {
            let extra = v.extra_data();
            if !extra.is_empty() {
                let sps_pps_annexb = H264Utils::to_annex_b(extra);
                let _ = detector.feed_packet(&sps_pps_annexb, 0, 0);
            }
        }

        let playing_session = match session.play(PlayOptions::default()).await {
            Ok(p) => p,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] play 失败: {e}，2秒后重试");
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut demuxed: Demuxed = match playing_session.demuxed() {
            Ok(d) => d,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] demuxed 失败: {e}，2秒后重试");
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut base_rtp_ts: Option<i64> = None;
        let mut frame_seq: u64 = 0;
        let mut consecutive_errors: u32 = 0;

        while let Some(item_res) = demuxed.next().await {
            match item_res {
                Ok(CodecItem::VideoFrame(frame)) => {
                    consecutive_errors = 0;
                    let rtp_ts: i64 = frame.timestamp().timestamp();
                    let data = frame.into_data();
                    if data.is_empty() {
                        continue;
                    }

                    let base = match base_rtp_ts {
                        Some(b) => b,
                        None => {
                            base_rtp_ts = Some(rtp_ts);
                            rtp_ts
                        }
                    };

                    let delta_ticks = rtp_ts.wrapping_sub(base);
                    let rtp_pts_ms = if delta_ticks >= 0 {
                        ((delta_ticks as u64) * 1000 / 90000) % 30000
                    } else {
                        0
                    };
                    let frame_pts_ms = (frame_seq * 1000 / 30) % 30000;
                    let pts_ms = if delta_ticks > 0 {
                        rtp_pts_ms
                    } else {
                        frame_pts_ms
                    };

                    let data_bytes = Bytes::from(data.clone());

                    let sample = Sample {
                        data: data_bytes,
                        duration: Duration::from_millis(33),
                        ..Default::default()
                    };

                    if let Err(e) = track.write_sample(&sample).await {
                        log::debug!("[rtsp:{stream_id}] write_sample: {e}");
                    }

                    let complete_nal = H264Utils::to_annex_b(&data);
                    let _ = vpu_feed_tx
                        .try_send((complete_nal, frame_seq, pts_ms as i64));

                    frame_seq += 1;
                }
                Ok(CodecItem::AudioFrame(_)) => {
                    consecutive_errors = 0;
                }
                Ok(_) => {
                    consecutive_errors = 0;
                }
                Err(e) => {
                    consecutive_errors += 1;
                    if consecutive_errors > 100 {
                        eprintln!("[rtsp:{stream_id}] 接收数据异常超限: {e}");
                        break;
                    }
                    log::debug!("[rtsp:{stream_id}] 忽略非致命数据异常包: {e}");
                    continue;
                }
            }
        }

        eprintln!("[rtsp:{stream_id}] rtsp 流断开或切流，立即重连...");
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}

fn run_vpu_feeder(
    mut rx: tokio::sync::mpsc::Receiver<(Vec<u8>, u64, i64)>,
    detector: Arc<FrameDetector>,
) {
    while let Some((nal_data, seq, pts)) = rx.blocking_recv() {
        let _ = detector.feed_packet(&nal_data, seq, pts);
    }
}

fn run_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
) {
    let mut last_processed_seq: Option<u64> = None;
    loop {
        match detector.detect_latest() {
            Ok(det_result) => {
                let cur_seq = det_result.frame_idx;
                if cur_seq.is_some() && cur_seq != last_processed_seq {
                    last_processed_seq = cur_seq;
                    dispatcher.publish(Arc::new(det_result));
                } else {
                    std::thread::sleep(Duration::from_millis(5));
                }
            }
            Err(_) => {
                std::thread::sleep(Duration::from_millis(10));
            }
        }
    }
}
