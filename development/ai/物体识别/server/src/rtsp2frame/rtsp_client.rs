use bytes::Bytes;
use futures::StreamExt;
use retina::client::{
    Demuxed, PlayOptions, Session, SessionOptions, SetupOptions, TcpTransportOptions, Transport,
};
use retina::codec::{CodecItem, FrameFormat};
use rtc::media::Sample;
use std::sync::Arc;
use std::time::Duration;
use url::Url;
use crate::detector::frame_detector::FrameDetector;

pub async fn run_rtsp_loop(
    stream_id: String,
    parsed_url: Url,
    detector: Option<Arc<FrameDetector>>,
    tx_video: tokio::sync::broadcast::Sender<Arc<Sample>>,
    vpu_feed_tx: Option<tokio::sync::mpsc::Sender<(Bytes, u64, i64, u64)>>,
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
                async_flush(&detector).await;
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
                async_flush(&detector).await;
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let encoding = session.streams()[stream_idx].encoding_name().to_ascii_lowercase();
        log::info!("[rtsp:{stream_id}] 视频轨编码识别 (sdp): {encoding}");
        async_create_channel(&detector, &encoding).await;

        let setup_opts = SetupOptions::default()
            .transport(Transport::Tcp(TcpTransportOptions::default()))
            .frame_format(FrameFormat::SIMPLE);
        if let Err(e) = session.setup(stream_idx, setup_opts).await {
            eprintln!("[rtsp:{stream_id}] setup 失败: {e}，2秒后重试");
            async_flush(&detector).await;
            tokio::time::sleep(Duration::from_secs(2)).await;
            continue;
        }

        let current_epoch = detector.as_ref().map(|d| d.flush_epoch()).unwrap_or(0);
        if let Some(ref feed_tx) = vpu_feed_tx {
            if let Some(retina::codec::ParametersRef::Video(v)) =
                session.streams()[stream_idx].parameters()
            {
                let extra = v.extra_data();
                if !extra.is_empty() {
                    let _ = feed_tx.send((Bytes::copy_from_slice(extra), u64::MAX, -1, current_epoch)).await;
                }
            }
        }

        let playing_session = match session.play(PlayOptions::default()).await {
            Ok(p) => p,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] play 失败: {e}，2秒后重试");
                async_flush(&detector).await;
                tokio::time::sleep(Duration::from_secs(2)).await;
                continue;
            }
        };

        let mut demuxed: Demuxed = match playing_session.demuxed() {
            Ok(d) => d,
            Err(e) => {
                eprintln!("[rtsp:{stream_id}] demuxed 失败: {e}，2秒后重试");
                async_flush(&detector).await;
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

                    if rtp_ts < base || rtp_ts - base > 90000 * 86400 * 365 {
                        base = rtp_ts;
                        base_rtp_ts = Some(base);
                        last_rtp_ts = None;
                    }

                    let delta_ticks = (rtp_ts - base) as u64;
                    let pts_ms = (delta_ticks * 1000 / 90000) as i64;

                    let sample_duration = match last_rtp_ts {
                        Some(last) => {
                            let diff = if rtp_ts > last {
                                (rtp_ts - last) as u64
                            } else {
                                0
                            };

                            if (450..=45000).contains(&diff) {
                                let dur = Duration::from_secs_f64(diff as f64 / 90000.0);
                                estimated_duration = dur;
                                if !detected_fps_logged {
                                    detected_fps_logged = true;
                                    log::info!(
                                        "[rtsp:{stream_id}] 动态自适应视频帧间隔: {:.2}ms (约 {:.1} fps)",
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

                    if let Some(ref feed_tx) = vpu_feed_tx {
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

                        match feed_tx.try_send((to_send, frame_seq, pts_ms as i64, current_epoch)) {
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
        async_flush(&detector).await;
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}

async fn async_flush(detector: &Option<Arc<FrameDetector>>) {
    if let Some(d) = detector {
        let d = Arc::clone(d);
        let _ = tokio::task::spawn_blocking(move || d.flush()).await;
    }
}

async fn async_create_channel(detector: &Option<Arc<FrameDetector>>, encoding: &str) {
    if let Some(d) = detector {
        let d = Arc::clone(d);
        let enc = encoding.to_string();
        let _ = tokio::task::spawn_blocking(move || {
            if let Err(e) = d.create_channel_with_codec(&enc) {
                eprintln!("[rtsp:{}] warning: create_channel_with_codec failed: {e}", d.stream_id());
            }
        }).await;
    }
}
