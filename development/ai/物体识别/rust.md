# rust

## 说明

rust 调用 rknn 的 so

## 步骤

依赖

```sh
cargo add tokio --features full
cargo add serde --features derive
cargo add webrtc@0.11 webrtc-util@0.9 retina@0.4
cargo add serde_json chrono log env_logger libloading bytes url futures
```

main.rs

```rust
pub mod detector;
pub mod rtsp2frame;
pub mod web_rtc;

use detector::frame_detector::FrameDetector;
use rtsp2frame::RtspStreamer;
use std::sync::Arc;
use tokio::sync::broadcast;
use web_rtc::WebRtcServer;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();
    let args: Vec<String> = std::env::args().collect();

    let rtsp_url = args
        .get(1)
        .cloned()
        .unwrap_or_else(|| "rtsp://127.0.0.1:8554/file_01".to_string());

    let http_addr = args
        .get(2)
        .cloned()
        .unwrap_or_else(|| "0.0.0.0:8181".to_string());

    println!("==================================================");
    println!("[server] 启动 rtsp -> webrtc + datachannel 目标检测服务");
    println!("  - 源地址  : {}", rtsp_url);
    println!("  - 信令地址: http://{}/offer", http_addr);
    println!("==================================================");

    let detector = Arc::new(
        FrameDetector::new("libdetect.so")
            .map_err(|e| format!("加载检测库 libdetect.so 失败: {e}"))?,
    );
    println!("[server] frame_detector 初始化成功 (dlopen: libdetect.so)");

    let (tx_detection, _rx) = broadcast::channel::<String>(256);

    let (webrtc_server, video_track) = WebRtcServer::new(&http_addr, tx_detection.clone());
    let webrtc_server = Arc::new(webrtc_server);

    println!("[server] 启动 RTSP 网络拉流推送: {}", rtsp_url);
    let streamer = RtspStreamer::new(&rtsp_url, Arc::clone(&detector), tx_detection);
    let _streamer_handle = streamer.start_stream(video_track).await?;

    webrtc_server.run_signaling_server().await?;

    Ok(())
}
```

rtsp2frame.rs

```rust
use bytes::Bytes;
use futures::StreamExt;
use retina::client::{Demuxed, PlayOptions, Session, SessionOptions, SetupOptions};
use retina::codec::{CodecItem, FrameFormat};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;
use url::Url;
use webrtc::media::Sample;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

use crate::detector::frame_detector::FrameDetector;

fn to_annex_b(input: &[u8]) -> Vec<u8> {
    if input.is_empty() {
        return Vec::new();
    }

    if input.starts_with(&[0, 0, 0, 1]) || input.starts_with(&[0, 0, 1]) {
        return input.to_vec();
    }

    let mut out = Vec::with_capacity(input.len() + 16);
    let mut offset = 0;
    let mut is_valid_avcc = true;

    while offset + 4 <= input.len() {
        let len = u32::from_be_bytes([input[offset], input[offset+1], input[offset+2], input[offset+3]]) as usize;
        if len == 0 || offset + 4 + len > input.len() {
            is_valid_avcc = false;
            break;
        }
        out.extend_from_slice(&[0x00, 0x00, 0x00, 0x01]);
        out.extend_from_slice(&input[offset + 4 .. offset + 4 + len]);
        offset += 4 + len;
    }

    if is_valid_avcc && offset == input.len() && !out.is_empty() {
        return out;
    }

    let mut fallback = Vec::with_capacity(4 + input.len());
    fallback.extend_from_slice(&[0x00, 0x00, 0x00, 0x01]);
    fallback.extend_from_slice(input);
    fallback
}

pub struct RtspStreamer {
    rtsp_url: String,
    detector: Arc<FrameDetector>,
    tx_detection: broadcast::Sender<String>,
}

impl RtspStreamer {
    pub fn new(
        rtsp_url: impl Into<String>,
        detector: Arc<FrameDetector>,
        tx_detection: broadcast::Sender<String>,
    ) -> Self {
        Self {
            rtsp_url: rtsp_url.into(),
            detector,
            tx_detection,
        }
    }

    pub async fn start_stream(
        &self,
        track: Arc<TrackLocalStaticSample>,
    ) -> Result<tokio::task::JoinHandle<()>, String> {
        let parsed_url = Url::parse(&self.rtsp_url).map_err(|e| format!("无效 RTSP URL: {e}"))?;
        let rtsp_url_str = self.rtsp_url.clone();
        let detector = Arc::clone(&self.detector);
        let tx_detection = self.tx_detection.clone();
        let detector_worker = Arc::clone(&detector);
        let tx_detection_worker = tx_detection.clone();
        let is_running = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let is_running_worker = Arc::clone(&is_running);

        let (vpu_feed_tx, mut vpu_feed_rx) = tokio::sync::mpsc::channel::<(Vec<u8>, u64, i64)>(500);
        let detector_feeder = Arc::clone(&detector);
        let is_running_feeder = Arc::clone(&is_running);

        tokio::task::spawn_blocking(move || {
            while is_running_feeder.load(std::sync::atomic::Ordering::Relaxed) {
                if let Some((nal_data, seq, pts)) = vpu_feed_rx.blocking_recv() {
                    let _ = detector_feeder.feed_packet(&nal_data, seq, pts);
                } else {
                    break;
                }
            }
        });

        tokio::task::spawn_blocking(move || {
            let mut last_processed_seq: Option<u64> = None;
            while is_running_worker.load(std::sync::atomic::Ordering::Relaxed) {
                match detector_worker.detect_latest() {
                    Ok(det_frame) => {
                        let cur_seq = det_frame.frame_idx;
                        if cur_seq.is_some() && cur_seq != last_processed_seq {
                            last_processed_seq = cur_seq;
                            let det_cnt = det_frame.detections.len();
                            let seq = det_frame.frame_idx.unwrap_or(0);
                            let pts = det_frame.pts_ms.unwrap_or(0);
                            if (det_cnt > 0 && seq % 90 == 0) || seq % 180 == 0 {
                                println!(
                                    "[rtsp_detection] NPU 实时检测帧 #{seq} (PTS: {pts}ms) -> 检测到 {det_cnt} 个目标"
                                );
                            }
                            let json_msg = serde_json::to_string(&det_frame).unwrap_or_default();
                            let _ = tx_detection_worker.send(json_msg);
                        } else {
                            std::thread::sleep(Duration::from_millis(5));
                        }
                    }
                    Err(_) => {
                        std::thread::sleep(Duration::from_millis(10));
                    }
                }
            }
        });

        let handle = tokio::spawn(async move {
            let mut retry_count = 0;
            loop {
                retry_count += 1;
                println!("[rtsp] 正在连接 rtsp 源: {rtsp_url_str} (重试 #{retry_count})");
                let session_options = SessionOptions::default()
                    .user_agent("rtsp-webrtc-streamer/1.0".to_owned());

                let session_res =
                    Session::describe(parsed_url.clone(), session_options).await;

                let mut session = match session_res {
                    Ok(s) => s,
                    Err(e) => {
                        eprintln!("[rtsp] 连接或 describe 失败: {e}，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let video_stream_idx = session.streams().iter().position(|s| s.media() == "video");

                let stream_idx = match video_stream_idx {
                    Some(idx) => idx,
                    None => {
                        eprintln!("[rtsp] 未在 rtsp 描述中找到视频轨，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let setup_opts = SetupOptions::default().frame_format(FrameFormat::SIMPLE);
                if let Err(e) = session.setup(stream_idx, setup_opts).await {
                    eprintln!("[rtsp] setup 视频流失败: {e}，5秒后重试");
                    tokio::time::sleep(Duration::from_secs(5)).await;
                    continue;
                }

                if let Some(retina::codec::ParametersRef::Video(v)) =
                    session.streams()[stream_idx].parameters()
                {
                    let extra = v.extra_data();
                    if !extra.is_empty() {
                        let sps_pps_annexb = to_annex_b(extra);
                        println!(
                            "[rtsp] 发现 SDP SPS/PPS 参数头 ({} 字节)，先行注入解码器...",
                            sps_pps_annexb.len()
                        );
                        let _ = detector.feed_packet(&sps_pps_annexb, 0, 0);
                    }
                }

                let playing_session = match session.play(PlayOptions::default()).await {
                    Ok(p) => p,
                    Err(e) => {
                        eprintln!("[rtsp] play 失败: {e}，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                println!("[rtsp] rtsp 播放已建立，开始接收视频 frame 并进行 PTS 精确校准");

                let mut demuxed: Demuxed = match playing_session.demuxed() {
                    Ok(d) => d,
                    Err(e) => {
                        eprintln!("[rtsp] demuxed 失败: {e}，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let mut base_rtp_ts: Option<i64> = None;
                let mut frame_seq: u64 = 0;

                while let Some(item_res) = demuxed.next().await {
                    match item_res {
                        Ok(CodecItem::VideoFrame(frame)) => {
                            let rtp_ts: i64 = frame.timestamp().timestamp();
                            let data = frame.into_data();
                            if data.is_empty() {
                                continue;
                            }

                            let base = *base_rtp_ts.get_or_insert(rtp_ts);
                            let delta_ticks = rtp_ts.wrapping_sub(base);
                            let rtp_pts_ms = if delta_ticks >= 0 {
                                ((delta_ticks as u64) * 1000 / 90000) % 30000
                            } else {
                                0
                            };
                            let frame_pts_ms = (frame_seq * 1000 / 30) % 30000;
                            let pts_ms = if delta_ticks > 0 { rtp_pts_ms } else { frame_pts_ms };

                            let data_bytes = Bytes::from(data.clone());

                            let sample = Sample {
                                data: data_bytes,
                                duration: Duration::from_millis(33),
                                ..Default::default()
                            };

                            if let Err(e) = track.write_sample(&sample).await {
                                log::debug!("[rtsp] write_sample: {e}");
                            }

                            let complete_nal = to_annex_b(&data);
                            let _ = vpu_feed_tx.try_send((complete_nal, frame_seq, pts_ms as i64));

                            frame_seq += 1;
                        }
                        Ok(CodecItem::AudioFrame(_)) => {}
                        Ok(_) => {}
                        Err(e) => {
                            eprintln!("[rtsp] 接收数据异常: {e}");
                            tokio::time::sleep(Duration::from_millis(500)).await;
                            break;
                        }
                    }
                }

                eprintln!("[rtsp] rtsp 流断开或切流，立即重连...");
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
        });

        Ok(handle)
    }
}
```

web_rtc.rs

```rust
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;
use tokio::sync::broadcast;
use tokio::sync::Mutex;
use webrtc::api::interceptor_registry::register_default_interceptors;
use webrtc::api::media_engine::MediaEngine;
use webrtc::api::APIBuilder;
use webrtc::interceptor::registry::Registry;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::peer_connection_state::RTCPeerConnectionState;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use webrtc::peer_connection::RTCPeerConnection;
use webrtc::rtp_transceiver::rtp_codec::RTCRtpCodecCapability;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;
use webrtc::track::track_local::TrackLocal;

pub struct WebRtcServer {
    http_addr: String,
    video_track: Arc<TrackLocalStaticSample>,
    tx_detection: broadcast::Sender<String>,
    active_connections: Arc<Mutex<HashMap<u64, Arc<RTCPeerConnection>>>>,
    next_conn_id: AtomicU64,
}

impl WebRtcServer {
    pub fn new(
        http_addr: impl Into<String>,
        tx_detection: broadcast::Sender<String>,
    ) -> (Self, Arc<TrackLocalStaticSample>) {
        let video_track = Arc::new(TrackLocalStaticSample::new(
            RTCRtpCodecCapability {
                mime_type: "video/H264".to_owned(),
                clock_rate: 90000,
                channels: 0,
                sdp_fmtp_line: "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f".to_owned(),
                rtcp_feedback: vec![],
            },
            "video0".to_owned(),
            "rtsp-stream".to_owned(),
        ));

        let server = Self {
            http_addr: http_addr.into(),
            video_track: Arc::clone(&video_track),
            tx_detection,
            active_connections: Arc::new(Mutex::new(HashMap::new())),
            next_conn_id: AtomicU64::new(1),
        };

        (server, video_track)
    }

    async fn handle_offer(&self, offer_sdp: &str) -> Result<String, String> {
        let mut m = MediaEngine::default();
        m.register_default_codecs().map_err(|e| e.to_string())?;
        let mut registry = Registry::new();
        registry = register_default_interceptors(registry, &mut m).map_err(|e| e.to_string())?;
        let api = APIBuilder::new()
            .with_media_engine(m)
            .with_interceptor_registry(registry)
            .build();

        let config = RTCConfiguration {
            ice_servers: vec![],
            ..Default::default()
        };
        let pc = Arc::new(
            api.new_peer_connection(config)
                .await
                .map_err(|e| e.to_string())?,
        );

        let conn_id = self.next_conn_id.fetch_add(1, Ordering::SeqCst);
        self.active_connections
            .lock()
            .await
            .insert(conn_id, Arc::clone(&pc));
        let pc_monitor = Arc::clone(&pc);
        let connections_ref = Arc::clone(&self.active_connections);

        pc.on_peer_connection_state_change(Box::new(move |s| {
            let pc_monitor = Arc::clone(&pc_monitor);
            let connections_ref = Arc::clone(&connections_ref);
            Box::pin(async move {
                if matches!(
                    s,
                    RTCPeerConnectionState::Failed
                        | RTCPeerConnectionState::Closed
                        | RTCPeerConnectionState::Disconnected
                ) {
                    connections_ref
                        .lock()
                        .await
                        .retain(|_, v| !Arc::ptr_eq(v, &pc_monitor));
                    println!("[webrtc] 连接状态改变: {s}，已释放连接 #{conn_id}");
                }
            })
        }));

        let sender = pc
            .add_track(Arc::clone(&self.video_track) as Arc<dyn TrackLocal + Send + Sync>)
            .await
            .map_err(|e| e.to_string())?;

        tokio::spawn(async move {
            let mut b = vec![0u8; 1500];
            while sender.read(&mut b).await.is_ok() {}
        });

        let tx_for_client_dc = self.tx_detection.clone();
        pc.on_data_channel(Box::new(move |dc| {
            let tx = tx_for_client_dc.clone();
            let dc_open = Arc::clone(&dc);
            Box::pin(async move {
                println!("[webrtc_datachannel] 客户端 DataChannel (label: {}) 协商成功，等待 Open 事件...", dc_open.label());
                let dc_task = Arc::clone(&dc_open);
                dc_open.on_open(Box::new(move || {
                    let dc = Arc::clone(&dc_task);
                    let mut rx = tx.subscribe();
                    println!("[webrtc_datachannel] DataChannel (label: {}) 已就绪 (Open)，启动实时目标检测数据广播", dc.label());
                    Box::pin(async move {
                        tokio::spawn(async move {
                            while let Ok(payload) = rx.recv().await {
                                if let Err(e) = dc.send_text(payload).await {
                                    log::debug!("[webrtc_datachannel] 发送失败: {e}");
                                    break;
                                }
                            }
                            println!("[webrtc_datachannel] 客户端 DataChannel 推送结束");
                        });
                    })
                }));
            })
        }));

        let offer =
            RTCSessionDescription::offer(offer_sdp.to_owned()).map_err(|e| e.to_string())?;
        pc.set_remote_description(offer)
            .await
            .map_err(|e| e.to_string())?;
        let answer = pc.create_answer(None).await.map_err(|e| e.to_string())?;
        let mut gather_complete = pc.gathering_complete_promise().await;
        pc.set_local_description(answer)
            .await
            .map_err(|e| e.to_string())?;

        let _ = tokio::time::timeout(std::time::Duration::from_millis(1500), gather_complete.recv()).await;

        let sdp = pc
            .local_description()
            .await
            .ok_or_else(|| "本地 SDP 不存在".to_string())?
            .sdp;
        Ok(sdp)
    }

    pub async fn run_signaling_server(self: Arc<Self>) -> std::io::Result<()> {
        let listener = TcpListener::bind(&self.http_addr).await?;
        println!("[webrtc_server] 信令监听 http://{}/offer", self.http_addr);

        loop {
            let (mut conn, _) = listener.accept().await?;
            let server = Arc::clone(&self);

            tokio::spawn(async move {
                let mut buf: Vec<u8> = Vec::new();
                let mut tmp = [0u8; 4096];
                let header_end = loop {
                    let n = match conn.read(&mut tmp).await {
                        Ok(0) | Err(_) => return,
                        Ok(n) => n,
                    };
                    buf.extend_from_slice(&tmp[..n]);
                    if let Some(pos) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
                        break pos + 4;
                    }
                    if buf.len() > (1 << 20) {
                        return;
                    }
                };

                let headers = String::from_utf8_lossy(&buf[..header_end]);
                let first_line = headers.lines().next().unwrap_or("");
                let mut parts = first_line.split_whitespace();
                let method = parts.next().unwrap_or("");
                let path = parts.next().unwrap_or("");

                let content_length = headers
                    .lines()
                    .find_map(|l| {
                        l.trim()
                            .to_ascii_lowercase()
                            .strip_prefix("content-length:")
                            .and_then(|v| v.trim().parse::<usize>().ok())
                    })
                    .unwrap_or(0);

                if method == "OPTIONS" {
                    let resp = concat!(
                        "HTTP/1.1 204 No Content\r\n",
                        "Access-Control-Allow-Origin: *\r\n",
                        "Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n",
                        "Access-Control-Allow-Headers: Content-Type\r\n",
                        "Connection: close\r\n",
                        "Content-Length: 0\r\n\r\n"
                    );
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    return;
                }

                if method == "POST" && path == "/offer" {
                    while buf.len() < header_end + content_length {
                        match conn.read(&mut tmp).await {
                            Ok(0) | Err(_) => return,
                            Ok(n) => buf.extend_from_slice(&tmp[..n]),
                        }
                    }
                    let body =
                        String::from_utf8_lossy(&buf[header_end..header_end + content_length])
                            .to_string();
                    match server.handle_offer(&body).await {
                        Ok(answer_sdp) => {
                            let resp = format!(
                                "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: application/sdp\r\nContent-Length: {}\r\n\r\n{}",
                                answer_sdp.len(),
                                answer_sdp
                            );
                            let _ = conn.write_all(resp.as_bytes()).await;
                            let _ = conn.flush().await;
                        }
                        Err(e) => {
                            let msg = format!("Offer 处理失败: {e}");
                            let resp = format!(
                                "HTTP/1.1 500 Internal Server Error\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                                msg.len()
                            );
                            let _ = conn.write_all(resp.as_bytes()).await;
                            let _ = conn.flush().await;
                        }
                    }
                } else if method == "GET" && path == "/health" {
                    let resp = "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: 2\r\n\r\nok";
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                } else {
                    let resp = "HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: 0\r\n\r\n";
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                }
            });
        }
    }
}
```

detector/mod.rs

```rust
pub mod detect_c_wrapper;
pub mod frame_detector;
pub mod types;
```

detector/types.rs

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionItem {
    pub class_id: Option<i32>,
    pub label: Option<String>,
    pub confidence: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rel_box: Option<Vec<f64>>,
    pub box_coord: Vec<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionFrame {
    pub timestamp: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_idx: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pts_ms: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_width: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frame_height: Option<i32>,
    pub detections: Vec<serde_json::Value>,
}

impl DetectionFrame {
    pub fn new(timestamp: i64, detections: Vec<serde_json::Value>) -> Self {
        Self {
            timestamp,
            frame_idx: None,
            pts_ms: None,
            frame_width: Some(1920),
            frame_height: Some(1080),
            detections,
        }
    }

    pub fn now(detections: Vec<serde_json::Value>) -> Self {
        Self {
            timestamp: chrono::Utc::now().timestamp_millis(),
            frame_idx: None,
            pts_ms: None,
            frame_width: Some(1920),
            frame_height: Some(1080),
            detections,
        }
    }
}
```

detector/frame_detector.rs

```rust
use std::sync::Arc;
use super::detect_c_wrapper::DetectCWrapper;
use super::types::DetectionFrame;

pub struct FrameDetector {
    detect_wrapper: Arc<DetectCWrapper>,
    default_width: i32,
    default_height: i32,
}

impl FrameDetector {
    pub fn new(so_path: &str) -> Result<Self, String> {
        let detect_wrapper = Arc::new(DetectCWrapper::new(so_path)?);
        Ok(Self {
            detect_wrapper,
            default_width: 1920,
            default_height: 1080,
        })
    }

    pub fn feed_packet(&self, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        self.detect_wrapper.push_video_packet(packet_data, frame_idx, pts_ms)
    }

    pub fn detect_latest(&self) -> Result<DetectionFrame, String> {
        let (raw_json, out_frame_idx, out_pts_ms) = self.detect_wrapper.detect_latest_frame()?;
        let parsed: serde_json::Value =
            serde_json::from_str(&raw_json).unwrap_or(serde_json::Value::Array(vec![]));

        let (frame_w, frame_h, f_idx, f_pts, mut detections) = if let serde_json::Value::Object(map) = parsed {
            let fw = map
                .get("frame_width")
                .and_then(|v| v.as_i64())
                .map(|v| v as i32)
                .filter(|&w| w > 0)
                .or(Some(self.default_width));
            let fh = map
                .get("frame_height")
                .and_then(|v| v.as_i64())
                .map(|v| v as i32)
                .filter(|&h| h > 0)
                .or(Some(self.default_height));
            let idx = map
                .get("frame_idx")
                .and_then(|v| v.as_u64())
                .unwrap_or(out_frame_idx);
            let pts = map
                .get("pts_ms")
                .and_then(|v| v.as_i64())
                .unwrap_or(out_pts_ms);
            let dets = map
                .get("detections")
                .and_then(|v| v.as_array())
                .cloned()
                .unwrap_or_default();
            (fw, fh, idx, pts, dets)
        } else {
            (Some(self.default_width), Some(self.default_height), out_frame_idx, out_pts_ms, vec![])
        };

        let fw_f = frame_w.unwrap_or(self.default_width) as f64;
        let fh_f = frame_h.unwrap_or(self.default_height) as f64;
        for det in &mut detections {
            if let serde_json::Value::Object(det_obj) = det {
                if !det_obj.contains_key("rel_box") {
                    if let Some(serde_json::Value::Array(box_arr)) = det_obj.get("box") {
                        if box_arr.len() >= 4 {
                            let x1 = box_arr[0].as_f64().unwrap_or(0.0);
                            let y1 = box_arr[1].as_f64().unwrap_or(0.0);
                            let x2 = box_arr[2].as_f64().unwrap_or(0.0);
                            let y2 = box_arr[3].as_f64().unwrap_or(0.0);

                            if x1 <= 1.0 && y1 <= 1.0 && x2 <= 1.0 && y2 <= 1.0 && (x2 > 0.0 || y2 > 0.0) {
                                det_obj.insert("rel_box".to_string(), serde_json::json!([x1, y1, x2, y2]));
                            } else if fw_f > 0.0 && fh_f > 0.0 {
                                let rx1 = (x1 / fw_f).clamp(0.0, 1.0);
                                let ry1 = (y1 / fh_f).clamp(0.0, 1.0);
                                let rx2 = (x2 / fw_f).clamp(0.0, 1.0);
                                let ry2 = (y2 / fh_f).clamp(0.0, 1.0);
                                det_obj.insert("rel_box".to_string(), serde_json::json!([rx1, ry1, rx2, ry2]));
                            }
                        }
                    }
                }
            }
        }

        Ok(DetectionFrame {
            timestamp: chrono::Utc::now().timestamp_millis(),
            frame_idx: Some(f_idx),
            pts_ms: Some(f_pts),
            frame_width: frame_w,
            frame_height: frame_h,
            detections,
        })
    }
}
```

detector/detect_c_wrapper.rs

```rust
use libloading::{Library, Symbol};
use std::ffi::CStr;
use std::os::raw::{c_char, c_int, c_uchar};

pub struct DetectCWrapper {
    _lib: Library,
    push_packet_fn: unsafe extern "C" fn(*const c_uchar, c_int, u64, i64) -> c_int,
    detect_latest_fn: unsafe extern "C" fn(*mut c_char, c_int, *mut u64, *mut i64) -> c_int,
}

unsafe impl Send for DetectCWrapper {}
unsafe impl Sync for DetectCWrapper {}

impl DetectCWrapper {
    pub fn new(library_path: &str) -> Result<Self, String> {
        unsafe {
            let lib = Library::new(library_path).map_err(|e| e.to_string())?;

            let push_packet_sym: Symbol<unsafe extern "C" fn(*const c_uchar, c_int, u64, i64) -> c_int> =
                lib.get(b"push_video_packet").map_err(|e| e.to_string())?;
            let push_packet_fn = *push_packet_sym;

            let detect_latest_sym: Symbol<unsafe extern "C" fn(*mut c_char, c_int, *mut u64, *mut i64) -> c_int> =
                lib.get(b"detect_latest_frame").map_err(|e| e.to_string())?;
            let detect_latest_fn = *detect_latest_sym;

            Ok(Self {
                _lib: lib,
                push_packet_fn,
                detect_latest_fn,
            })
        }
    }

    pub fn push_video_packet(&self, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        if packet_data.is_empty() {
            return Ok(());
        }

        unsafe {
            let ret = (self.push_packet_fn)(
                packet_data.as_ptr(),
                packet_data.len() as c_int,
                frame_idx,
                pts_ms,
            );
            if ret < 0 {
                return Err("push_video_packet returned error code".into());
            }
            Ok(())
        }
    }

    pub fn detect_latest_frame(&self) -> Result<(String, u64, i64), String> {
        unsafe {
            let mut buffer = vec![0u8; 8192];
            let mut out_frame_idx: u64 = 0;
            let mut out_pts_ms: i64 = 0;
            let ret = (self.detect_latest_fn)(
                buffer.as_mut_ptr() as *mut c_char,
                buffer.len() as c_int,
                &mut out_frame_idx,
                &mut out_pts_ms,
            );

            if ret < 0 {
                return Err("detect_latest_frame returned error code".into());
            }

            let c_str = CStr::from_ptr(buffer.as_ptr() as *const c_char);
            let result_str = c_str.to_string_lossy().into_owned();
            Ok((result_str, out_frame_idx, out_pts_ms))
        }
    }
}
```

build.sh

```sh
#!/bin/bash

set -e

# webrtc 依赖 ring, ring 基于 c
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)
WORKSPACE_DIR=$(cd "${CURRENT_DIR}/.." && pwd)
TOOLCHAIN_DIR="${WORKSPACE_DIR}/toolchain"

if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
fi

export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-none-linux-gnu-gcc
export CC_aarch64_unknown_linux_gnu=aarch64-none-linux-gnu-gcc

cargo build --release --target=aarch64-unknown-linux-gnu
```
