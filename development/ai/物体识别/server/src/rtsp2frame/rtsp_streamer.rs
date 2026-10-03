use bytes::Bytes;
use futures::StreamExt;
use retina::client::{Demuxed, PlayOptions, Session, SessionOptions, SetupOptions};
use retina::codec::{CodecItem, FrameFormat};
use rtc::media::Sample;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use url::Url;
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
            let _guard = ScopeExitGuard {
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

struct ScopeExitGuard {
    epoch: u64,
    running: Arc<AtomicBool>,
    detector: Arc<FrameDetector>,
}

impl Drop for ScopeExitGuard {
    fn drop(&mut self) {
        self.running.store(false, Ordering::Relaxed);
        let detector = Arc::clone(&self.detector);
        let my_epoch = self.epoch;
        if let Ok(handle) = tokio::runtime::Handle::try_current() {
            handle.spawn(async move {
                tokio::time::sleep(Duration::from_millis(500)).await;
                if detector.session_epoch() == my_epoch {
                    let _ = detector.release_channel();
                    log::info!("[rtsp_streamer:{}] rtsp 主循环退出，已触发通道显存释放与检测线程终止", detector.stream_id());
                } else {
                    log::info!("[rtsp_streamer:{}] 忽略旧会话的延迟释放 (epoch: {} != {})", detector.stream_id(), my_epoch, detector.session_epoch());
                }
            });
        } else {
            let _ = detector.release_channel();
        }
    }
}

fn spawn_vpu_feeder(
    rx: tokio::sync::mpsc::Receiver<(Bytes, u64, i64, u64)>,
    detector: Arc<FrameDetector>,
    running: Arc<AtomicBool>,
) {
    tokio::task::spawn_blocking(move || run_vpu_feeder(rx, detector, running));
}

fn spawn_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
    running: Arc<AtomicBool>,
) {
    tokio::task::spawn_blocking(move || run_detection(detector, dispatcher, running));
}

async fn run_rtsp_loop(
    stream_id: String,
    parsed_url: Url,
    detector: Arc<FrameDetector>,
    tx_video: tokio::sync::broadcast::Sender<Arc<Sample>>,
    vpu_feed_tx: tokio::sync::mpsc::Sender<(Bytes, u64, i64, u64)>,
) {
    loop {
        let mut frame_seq: u64 = 0;
        let mut dropped_feed_frames: u64 = 0;
        let mut waiting_for_keyframe = false;
        let session_options =
            SessionOptions::default().user_agent("rtsp-webrtc-streamer/1.0".to_owned());

        let session_res =
            Session::describe(parsed_url.clone(), session_options).await;

        let mut session = match session_res {
            Ok(s) => s,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] describe 失败: {e}，2秒后重试");
                let _ = detector.flush();
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
                let _ = detector.flush();
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let encoding = session.streams()[stream_idx].encoding_name().to_ascii_lowercase();
        log::info!("[rtsp:{stream_id}] 视频轨编码识别 (SDP): {encoding}");
        if let Err(e) = detector.create_channel_with_codec(&encoding) {
            eprintln!("[rtsp:{stream_id}] warning: create_channel_with_codec failed: {e}");
        }

        let setup_opts = SetupOptions::default().frame_format(FrameFormat::SIMPLE);
        if let Err(e) = session.setup(stream_idx, setup_opts).await {
            eprintln!("[rtsp:{stream_id}] setup 失败: {e}，2秒后重试");
            let _ = detector.flush();
            tokio::time::sleep(Duration::from_secs(2)).await;
            continue;
        }

        let current_epoch = detector.flush_epoch();
        if let Some(retina::codec::ParametersRef::Video(v)) =
            session.streams()[stream_idx].parameters()
        {
            let extra = v.extra_data();
            if !extra.is_empty() {
                let _ = vpu_feed_tx.send((Bytes::copy_from_slice(extra), u64::MAX, -1, current_epoch)).await;
            }
        }

        let playing_session = match session.play(PlayOptions::default()).await {
            Ok(p) => p,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] play 失败: {e}，2秒后重试");
                let _ = detector.flush();
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut demuxed: Demuxed = match playing_session.demuxed() {
            Ok(d) => d,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] demuxed 失败: {e}，2秒后重试");
                let _ = detector.flush();
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut base_rtp_ts: Option<i64> = None;
        let mut last_rtp_ts: Option<i64> = None;
        let mut estimated_duration = Duration::from_millis(33);
        let mut detected_fps_logged = false;
        let mut consecutive_errors: u32 = 0;

        while let Some(item_res) = demuxed.next().await {
            match item_res {
                Ok(CodecItem::VideoFrame(frame)) => {
                    consecutive_errors = 0;
                    let rtp_ts: i64 = frame.timestamp().timestamp();
                    let is_key = frame.is_random_access_point();
                    let data = frame.into_data();
                    if data.is_empty() {
                        continue;
                    }

                    let mut base = match base_rtp_ts {
                        Some(b) => b,
                        None => {
                            base_rtp_ts = Some(rtp_ts);
                            rtp_ts
                        }
                    };

                    let delta_ticks = (rtp_ts.wrapping_sub(base) as u32) as u64;
                    if rtp_ts < base - 90000 || delta_ticks > 90000 * 3600 {
                        base = rtp_ts;
                        base_rtp_ts = Some(base);
                        last_rtp_ts = None;
                    }

                    let rtp_pts_ms = ((rtp_ts.wrapping_sub(base) as u32) as u64) * 1000 / 90000;
                    let pts_ms = rtp_pts_ms;

                    let sample_duration = match last_rtp_ts {
                        Some(last) => {
                            let diff = (rtp_ts.wrapping_sub(last) as u32) as u64;
                            // 450 ticks (5ms, 200fps) ~ 45000 ticks (500ms, 2fps)
                            if (450..=45000).contains(&diff) {
                                let dur = Duration::from_secs_f64(diff as f64 / 90000.0);
                                estimated_duration = dur;
                                if !detected_fps_logged {
                                    detected_fps_logged = true;
                                    log::info!(
                                        "[rtsp:{stream_id}] 动态自适应视频帧间隔: {:.2}ms (约 {:.1} FPS)",
                                        dur.as_secs_f64() * 1000.0,
                                        90000.0 / diff as f64
                                    );
                                }
                                dur
                            } else {
                                estimated_duration
                            }
                        }
                        None => estimated_duration,
                    };
                    last_rtp_ts = Some(rtp_ts);

                    let sample_data = Bytes::from(data);

                    let sample = Sample {
                        data: sample_data.clone(),
                        duration: sample_duration,
                        ..Default::default()
                    };

                    let _ = tx_video.send(Arc::new(sample));

                    if waiting_for_keyframe {
                        if is_key {
                            waiting_for_keyframe = false;
                            log::info!("[rtsp:{stream_id}] 捕获到新关键帧，恢复 vpu 解码送流");
                        } else {
                            frame_seq += 1;
                            continue;
                        }
                    }

                    let to_send = sample_data.clone();

                    match vpu_feed_tx.try_send((to_send, frame_seq, pts_ms as i64, current_epoch)) {
                        Ok(()) => {}
                        Err(tokio::sync::mpsc::error::TrySendError::Full(_)) => {
                            dropped_feed_frames += 1;
                            waiting_for_keyframe = true;
                            if dropped_feed_frames % 60 == 1 {
                                log::warn!("[rtsp:{stream_id}] vpu 解码队列积压 (已跳过 {dropped_feed_frames} 帧)，等待下一个关键帧以防花屏");
                            }
                        }
                        Err(tokio::sync::mpsc::error::TrySendError::Closed(_)) => {
                            log::error!("[rtsp:{stream_id}] vpu 送流通道已关闭");
                            break;
                        }
                    }

                    frame_seq += 1;
                }
                Ok(CodecItem::AudioFrame(_)) => {
                    consecutive_errors = 0;
                }
                Ok(_) => {
                    consecutive_errors = 0;
                }
                Err(e) => {
                    let err_str = e.to_string();
                    if err_str.contains("EOF")
                        || err_str.contains("closed")
                        || err_str.contains("Reset")
                        || err_str.contains("Broken pipe")
                        || err_str.contains("TimedOut")
                        || consecutive_errors > 10
                    {
                        log::warn!("[rtsp:{stream_id}] rtsp 流结束或连接断开 ({e})，准备重连");
                        break;
                    }
                    consecutive_errors += 1;
                    log::debug!("[rtsp:{stream_id}] 忽略非致命数据异常包 (连续第 {consecutive_errors} 次): {e}");
                    continue;
                }
            }
        }

        log::info!("[rtsp:{stream_id}] rtsp 流断开或切流，立即重连...");
        let _ = detector.flush();
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
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

fn run_detection(
    detector: Arc<FrameDetector>,
    dispatcher: Arc<DetectedDispatcher>,
    running: Arc<AtomicBool>,
) {
    let mut last_processed_seq: Option<u64> = None;
    let mut last_detect_time = std::time::Instant::now();
    let mut last_epoch = detector.flush_epoch();

    while running.load(Ordering::Relaxed) {
        let cur_epoch = detector.flush_epoch();
        if cur_epoch != last_epoch {
            last_epoch = cur_epoch;
            last_processed_seq = None;
        }

        let elapsed = last_detect_time.elapsed();
        if elapsed < Duration::from_millis(15) {
            std::thread::sleep(Duration::from_millis(15) - elapsed);
        }
        match detector.detect_latest() {
            Ok(Some(det_result)) => {
                let cur_seq = det_result.frame_idx;
                if cur_seq.is_some() && cur_seq != last_processed_seq {
                    last_processed_seq = cur_seq;
                    last_detect_time = std::time::Instant::now();
                    dispatcher.publish(Arc::new(det_result));
                } else {
                    std::thread::sleep(Duration::from_millis(10));
                }
            }
            Ok(None) => {
                std::thread::sleep(Duration::from_millis(12));
            }
            Err(_) => {
                std::thread::sleep(Duration::from_millis(20));
            }
        }
    }
    log::info!("[detection:{}] 检测后台线程已安全退出", detector.stream_id());
}
