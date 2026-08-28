# rust

## 说明

rust 调用 rknn 的 so

## 步骤

依赖

```sh
cargo add tokio --features full
cargo add serde --features derive
cargo add webrtc@0.11
cargo add webrtc-util@0.9
cargo add retina@0.4
cargo add serde_json@1.0
cargo add chrono@0.4
cargo add log@0.4
cargo add env_logger@0.10
cargo add libloading@0.8
cargo add bytes@1.0
cargo add url@2.5
cargo add futures@0.3
```

src/detector/detect_c_wrapper.rs

```rust
use std::ffi::CStr;
use std::os::raw::{c_char, c_int, c_uchar};

unsafe extern "C" {
    fn bin_to_img_stream(
        ch: c_int,
        packet_data: *const c_uchar,
        packet_size: c_int,
        frame_idx: u64,
        pts_ms: i64,
    ) -> c_int;

    fn detect_img_bin(
        ch: c_int,
        out_buf: *mut c_char,
        out_buf_size: c_int,
        out_frame_idx: *mut u64,
        out_pts_ms: *mut i64,
    ) -> c_int;
}

#[derive(Default, Debug, Clone, Copy)]
pub struct DetectCWrapper;

unsafe impl Send for DetectCWrapper {}
unsafe impl Sync for DetectCWrapper {}

impl DetectCWrapper {
    pub fn new() -> Self {
        Self
    }

    pub fn bin_to_img_stream(&self, ch: u32, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        if packet_data.is_empty() {
            return Ok(());
        }

        unsafe {
            let ret = bin_to_img_stream(
                ch as c_int,
                packet_data.as_ptr(),
                packet_data.len() as c_int,
                frame_idx,
                pts_ms,
            );

            if ret < 0 {
                return Err(format!("bin_to_img_stream (ch={ch}) returned error code: {ret}"));
            }
            Ok(())
        }
    }

    pub fn detect_img_bin(&self, ch: u32) -> Result<(String, u64, i64), String> {
        unsafe {
            let mut buffer = vec![0u8; 65536];
            let mut out_frame_idx: u64 = 0;
            let mut out_pts_ms: i64 = 0;

            let ret = detect_img_bin(
                ch as c_int,
                buffer.as_mut_ptr() as *mut c_char,
                buffer.len() as c_int,
                &mut out_frame_idx,
                &mut out_pts_ms,
            );

            if ret < 0 {
                return Err(format!("detect_img_bin (ch={ch}) returned error code: {ret}"));
            }

            let c_str = CStr::from_ptr(buffer.as_ptr() as *const c_char);
            let result_str = c_str.to_string_lossy().into_owned();
            Ok((result_str, out_frame_idx, out_pts_ms))
        }
    }
}
```

src/detector/frame_detector.rs

```rust
use std::sync::Arc;
use super::detect_c_wrapper::DetectCWrapper;
use super::types::DetectionFrame;

pub struct FrameDetector {
    detect_wrapper: Arc<DetectCWrapper>,
    channel_id: u32,
    stream_id: String,
    default_width: i32,
    default_height: i32,
}

impl FrameDetector {
    pub fn with_channel(
        detect_wrapper: Arc<DetectCWrapper>,
        channel_id: u32,
        stream_id: impl Into<String>,
    ) -> Self {
        Self {
            detect_wrapper,
            channel_id,
            stream_id: stream_id.into(),
            default_width: 1920,
            default_height: 1080,
        }
    }

    pub fn channel_id(&self) -> u32 {
        self.channel_id
    }

    pub fn stream_id(&self) -> &str {
        &self.stream_id
    }

    pub fn feed_packet(&self, packet_data: &[u8], frame_idx: u64, pts_ms: i64) -> Result<(), String> {
        self.detect_wrapper.bin_to_img_stream(self.channel_id, packet_data, frame_idx, pts_ms)
    }

    pub fn detect_latest(&self) -> Result<DetectionFrame, String> {
        let (raw_json, out_frame_idx, out_pts_ms) = self.detect_wrapper.detect_img_bin(self.channel_id)?;
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
            id: self.stream_id.clone(),
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

src/detector/types.rs

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
    pub id: String,
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
    pub fn new(timestamp: i64, id: impl Into<String>, detections: Vec<serde_json::Value>) -> Self {
        Self {
            id: id.into(),
            timestamp,
            frame_idx: None,
            pts_ms: None,
            frame_width: Some(1920),
            frame_height: Some(1080),
            detections,
        }
    }

    pub fn now(id: impl Into<String>, detections: Vec<serde_json::Value>) -> Self {
        Self {
            id: id.into(),
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

src/detector/mod.rs

```rust
pub mod detect_c_wrapper;
pub mod frame_detector;
pub mod types;
```

src/config.rs

```rust
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub server: ServerOutputConfig,
    #[serde(alias = "streams")]
    pub input: StreamConfigInput,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerOutputConfig {
    pub host: String,
    pub port: u16,
    #[serde(default)]
    pub http_addr: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum StreamConfigInput {
    Map(HashMap<String, StreamEntry>),
    List(Vec<StreamItem>),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum StreamEntry {
    Url(String),
    Detail(StreamDetail),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum StreamItem {
    Url(String),
    Detail(StreamDetail),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreamDetail {
    #[serde(default)]
    pub name: Option<String>,
    #[serde(default)]
    pub id: Option<String>,
    #[serde(default)]
    pub input: Option<String>,
    #[serde(default)]
    pub url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
}

pub fn extract_stream_id_from_url(url: &str) -> String {
    let clean = url.split('?').next().unwrap_or(url);
    let clean = clean.split('#').next().unwrap_or(clean);
    let trimmed = clean.trim_end_matches('/');
    if let Some(pos) = trimmed.rfind('/') {
        let seg = &trimmed[pos + 1..];
        if !seg.is_empty() {
            return seg.to_string();
        }
    }
    if !trimmed.is_empty() {
        trimmed.to_string()
    } else {
        "stream".to_string()
    }
}

impl ServerConfig {
    pub fn http_addr(&self) -> String {
        if let Some(ref addr) = self.server.http_addr {
            return addr.clone();
        }
        format!("{}:{}", self.server.host, self.server.port)
    }

    pub fn get_streams(&self) -> Vec<StreamConfig> {
        let mut result = Vec::new();
        match &self.input {
            StreamConfigInput::Map(map) => {
                let mut sorted_keys: Vec<&String> = map.keys().collect();
                sorted_keys.sort();
                for key in sorted_keys {
                    let entry = &map[key];
                    let input_url = match entry {
                        StreamEntry::Url(url) => url.clone(),
                        StreamEntry::Detail(d) => d
                            .input
                            .as_ref()
                            .or(d.url.as_ref())
                            .cloned()
                            .unwrap_or_default(),
                    };
                    if !input_url.is_empty() {
                        let id = if !key.is_empty() {
                            key.clone()
                        } else {
                            extract_stream_id_from_url(&input_url)
                        };
                        result.push(StreamConfig { id, input: input_url });
                    }
                }
            }
            StreamConfigInput::List(list) => {
                for (idx, item) in list.iter().enumerate() {
                    match item {
                        StreamItem::Url(url) => {
                            if !url.is_empty() {
                                let id = extract_stream_id_from_url(url);
                                result.push(StreamConfig {
                                    id: if id.is_empty() { format!("stream_{idx}") } else { id },
                                    input: url.clone(),
                                });
                            }
                        }
                        StreamItem::Detail(d) => {
                            let input_url = d
                                .input
                                .as_ref()
                                .or(d.url.as_ref())
                                .cloned()
                                .unwrap_or_default();
                            if !input_url.is_empty() {
                                let explicit_id = d.id.as_ref().or(d.name.as_ref());
                                let id = explicit_id
                                    .cloned()
                                    .unwrap_or_else(|| extract_stream_id_from_url(&input_url));
                                result.push(StreamConfig {
                                    id: if id.is_empty() { format!("stream_{idx}") } else { id },
                                    input: input_url,
                                });
                            }
                        }
                    }
                }
            }
        }
        result
    }

    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = fs::read_to_string(&path)?;
        if let Ok(cfg) = serde_json::from_str::<ServerConfig>(&content) {
            return Ok(cfg);
        }
        match Self::parse_yaml_content(&content) {
            Ok(cfg) => Ok(cfg),
            Err(e) => Err(format!("配置文件 '{}' 解析失败: {e}", path.as_ref().display()).into()),
        }
    }

    fn parse_yaml_content(content: &str) -> Result<Self, String> {
        let mut current_section = String::new();
        let mut server_host: Option<String> = None;
        let mut server_port: Option<u16> = None;
        let mut http_addr: Option<String> = None;
        let mut streams_map = HashMap::new();

        for line_raw in content.lines() {
            let line_no_comment = if let Some(idx) = line_raw.find('#') {
                &line_raw[..idx]
            } else {
                line_raw
            };
            let line_trimmed = line_no_comment.trim();
            if line_trimmed.is_empty() {
                continue;
            }

            let indent = line_no_comment.chars().take_while(|c| c.is_whitespace()).count();

            if indent == 0 && line_trimmed.ends_with(':') {
                current_section = line_trimmed.trim_end_matches(':').trim().to_lowercase();
                continue;
            }

            if current_section == "server" || current_section == "output" || current_section == "api" {
                if let Some((k, v)) = line_trimmed.split_once(':') {
                    let k = k.trim().to_lowercase();
                    let v = v.trim().trim_matches('"').trim_matches('\'').trim();
                    match k.as_str() {
                        "port" | "listen_port" => {
                            if let Ok(p) = v.parse::<u16>() {
                                server_port = Some(p);
                            }
                        }
                        "host" | "bind" => {
                            server_host = Some(v.to_string());
                        }
                        "http_addr" | "listen" | "address" => {
                            http_addr = Some(v.to_string());
                        }
                        _ => {}
                    }
                }
            } else if current_section == "input" || current_section == "streams" {
                if line_trimmed.starts_with("- ") {
                    let val = line_trimmed.strip_prefix("- ").unwrap().trim().trim_matches('"').trim_matches('\'').trim();
                    if let Some((k, v)) = val.split_once(':') {
                        let k = k.trim();
                        let v = v.trim().trim_matches('"').trim_matches('\'').trim();
                        if k == "input" || k == "url" {
                            let stream_id = extract_stream_id_from_url(v);
                            streams_map.insert(stream_id, StreamEntry::Url(v.to_string()));
                        }
                    } else if !val.is_empty() {
                        let stream_id = extract_stream_id_from_url(val);
                        streams_map.insert(stream_id, StreamEntry::Url(val.to_string()));
                    }
                } else if let Some((k, v)) = line_trimmed.split_once(':') {
                    let k = k.trim().trim_matches('"').trim_matches('\'').trim().to_string();
                    let v = v.trim().trim_matches('"').trim_matches('\'').trim().to_string();
                    if !k.is_empty() && !v.is_empty() {
                        streams_map.insert(k, StreamEntry::Url(v));
                    }
                }
            }
        }

        let host = server_host.unwrap_or_else(|| "0.0.0.0".to_string());
        let port = server_port.unwrap_or(8181);

        if streams_map.is_empty() {
            return Err("未在 YAML 配置文件中找到任何有效的 streams / input 定义".to_string());
        }

        Ok(ServerConfig {
            server: ServerOutputConfig {
                host,
                port,
                http_addr,
            },
            input: StreamConfigInput::Map(streams_map),
        })
    }
}
```

src/rtsp2frame.rs

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
    stream_id: String,
    rtsp_url: String,
    detector: Arc<FrameDetector>,
    tx_detection: broadcast::Sender<String>,
}

impl RtspStreamer {
    pub fn new(
        stream_id: impl Into<String>,
        rtsp_url: impl Into<String>,
        detector: Arc<FrameDetector>,
        tx_detection: broadcast::Sender<String>,
    ) -> Self {
        Self {
            stream_id: stream_id.into(),
            rtsp_url: rtsp_url.into(),
            detector,
            tx_detection,
        }
    }

    pub fn stream_id(&self) -> &str {
        &self.stream_id
    }

    pub async fn start_stream(
        &self,
        track: Arc<TrackLocalStaticSample>,
    ) -> Result<tokio::task::JoinHandle<()>, String> {
        let parsed_url = Url::parse(&self.rtsp_url).map_err(|e| format!("无效 RTSP URL ({}): {e}", self.rtsp_url))?;
        let stream_id = self.stream_id.clone();
        let detector = Arc::clone(&self.detector);
        let tx_detection = self.tx_detection.clone();
        let detector_worker = Arc::clone(&detector);
        let tx_detection_worker = tx_detection.clone();
        let is_running = Arc::new(std::sync::atomic::AtomicBool::new(true));
        let is_running_worker = Arc::clone(&is_running);

        let (vpu_feed_tx, mut vpu_feed_rx) = tokio::sync::mpsc::channel::<(Vec<u8>, u64, i64)>(256);
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
            loop {
                let session_options = SessionOptions::default()
                    .user_agent("rtsp-webrtc-streamer/1.0".to_owned());

                let session_res =
                    Session::describe(parsed_url.clone(), session_options).await;

                let mut session = match session_res {
                    Ok(s) => s,
                    Err(e) => {
                        eprintln!("[rtsp:{stream_id}] describe 失败: {e}，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let video_stream_idx = session.streams().iter().position(|s| s.media() == "video");

                let stream_idx = match video_stream_idx {
                    Some(idx) => idx,
                    None => {
                        eprintln!("[rtsp:{stream_id}] 未在 rtsp 中找到视频轨，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let setup_opts = SetupOptions::default().frame_format(FrameFormat::SIMPLE);
                if let Err(e) = session.setup(stream_idx, setup_opts).await {
                    eprintln!("[rtsp:{stream_id}] setup 失败: {e}，5秒后重试");
                    tokio::time::sleep(Duration::from_secs(5)).await;
                    continue;
                }

                if let Some(retina::codec::ParametersRef::Video(v)) =
                    session.streams()[stream_idx].parameters()
                {
                    let extra = v.extra_data();
                    if !extra.is_empty() {
                        let sps_pps_annexb = to_annex_b(extra);
                        let _ = detector.feed_packet(&sps_pps_annexb, 0, 0);
                    }
                }

                let playing_session = match session.play(PlayOptions::default()).await {
                    Ok(p) => p,
                    Err(e) => {
                        eprintln!("[rtsp:{stream_id}] play 失败: {e}，5秒后重试");
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        continue;
                    }
                };

                let mut demuxed: Demuxed = match playing_session.demuxed() {
                    Ok(d) => d,
                    Err(e) => {
                        eprintln!("[rtsp:{stream_id}] demuxed 失败: {e}，5秒后重试");
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
                                log::debug!("[rtsp:{stream_id}] write_sample: {e}");
                            }

                            let complete_nal = to_annex_b(&data);
                            let _ = vpu_feed_tx.try_send((complete_nal, frame_seq, pts_ms as i64));

                            frame_seq += 1;
                        }
                        Ok(CodecItem::AudioFrame(_)) => {}
                        Ok(_) => {}
                        Err(e) => {
                            eprintln!("[rtsp:{stream_id}] 接收数据异常: {e}");
                            tokio::time::sleep(Duration::from_millis(500)).await;
                            break;
                        }
                    }
                }

                eprintln!("[rtsp:{stream_id}] rtsp 流断开或切流，立即重连...");
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
        });

        Ok(handle)
    }
}
```

src/web_rtc.rs

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

#[derive(Clone)]
pub struct StreamContext {
    pub stream_id: String,
    pub input_url: String,
    pub video_track: Arc<TrackLocalStaticSample>,
    pub tx_detection: broadcast::Sender<String>,
}

pub struct WebRtcServer {
    http_addr: String,
    streams: Arc<HashMap<String, StreamContext>>,
    stream_order: Vec<String>,
    default_stream_id: Option<String>,
    active_connections: Arc<Mutex<HashMap<u64, Arc<RTCPeerConnection>>>>,
    next_conn_id: AtomicU64,
}

impl WebRtcServer {
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

    pub fn new(
        http_addr: impl Into<String>,
        stream_contexts: Vec<StreamContext>,
    ) -> Self {
        let mut streams = HashMap::new();
        let mut stream_order = Vec::new();
        let mut default_stream_id = None;

        for ctx in stream_contexts {
            if default_stream_id.is_none() {
                default_stream_id = Some(ctx.stream_id.clone());
            }
            stream_order.push(ctx.stream_id.clone());
            streams.insert(ctx.stream_id.clone(), ctx);
        }

        Self {
            http_addr: http_addr.into(),
            streams: Arc::new(streams),
            stream_order,
            default_stream_id,
            active_connections: Arc::new(Mutex::new(HashMap::new())),
            next_conn_id: AtomicU64::new(1),
        }
    }

    fn resolve_stream_id(&self, path: &str) -> Option<String> {
        if let Some(query_idx) = path.find('?') {
            let query = &path[query_idx + 1..];
            for pair in query.split('&') {
                if let Some((k, v)) = pair.split_once('=') {
                    if (k == "src" || k == "stream" || k == "id") && !v.is_empty() {
                        let decoded = v.replace("%2F", "/");
                        if self.streams.contains_key(&decoded) {
                            return Some(decoded);
                        }
                    }
                }
            }
        }

        let raw_path = path.split('?').next().unwrap_or(path);
        let raw_path = raw_path.trim_end_matches('/');

        let sub = raw_path.strip_prefix('/').unwrap_or(raw_path);
        if let Some(seg) = sub.strip_prefix("offer/") {
            if self.streams.contains_key(seg) {
                return Some(seg.to_string());
            }
        }
        if !sub.is_empty() && sub != "health" && sub != "streams" && sub != "api" {
            if self.streams.contains_key(sub) {
                return Some(sub.to_string());
            }
            return Some(sub.to_string());
        }

        self.default_stream_id.clone()
    }

    async fn handle_offer(&self, stream_id: &str, offer_sdp: &str) -> Result<String, String> {
        let stream_ctx = self.streams.get(stream_id).ok_or_else(|| {
            format!(
                "未找到指定的流 ID '{}'。当前已加载的可用流: {:?}",
                stream_id, self.stream_order
            )
        })?;

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
                }
            })
        }));

        let sender = pc
            .add_track(Arc::clone(&stream_ctx.video_track) as Arc<dyn TrackLocal + Send + Sync>)
            .await
            .map_err(|e| e.to_string())?;

        tokio::spawn(async move {
            let mut b = vec![0u8; 1500];
            while sender.read(&mut b).await.is_ok() {}
        });

        let tx_for_client_dc = stream_ctx.tx_detection.clone();
        pc.on_data_channel(Box::new(move |dc| {
            let tx = tx_for_client_dc.clone();
            let dc_clone = Arc::clone(&dc);
            Box::pin(async move {
                let started = Arc::new(std::sync::atomic::AtomicBool::new(false));
                let started_clone = Arc::clone(&started);
                let dc_task = Arc::clone(&dc_clone);
                let tx_task = tx.clone();

                let spawn_sender = move || {
                    if !started_clone.swap(true, std::sync::atomic::Ordering::SeqCst) {
                        let dc = Arc::clone(&dc_task);
                        let mut rx = tx_task.subscribe();
                        tokio::spawn(async move {
                            loop {
                                match rx.recv().await {
                                    Ok(payload) => {
                                        if dc.send_text(payload).await.is_err() {
                                            break;
                                        }
                                    }
                                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                                        continue;
                                    }
                                    Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                                        break;
                                    }
                                }
                            }
                        });
                    }
                };

                let spawn_on_open = spawn_sender.clone();
                dc_clone.on_open(Box::new(move || {
                    spawn_on_open();
                    Box::pin(async move {})
                }));

                if dc_clone.ready_state() == webrtc::data_channel::data_channel_state::RTCDataChannelState::Open {
                    spawn_sender();
                }
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
            .ok_or_else(|| "本地 sdp 不存在".to_string())?
            .sdp;
        Ok(sdp)
    }

    pub async fn run_signaling_server(self: Arc<Self>) -> std::io::Result<()> {
        let listener = TcpListener::bind(&self.http_addr).await?;

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

                if method == "GET" && path == "/health" {
                    let resp = "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Length: 2\r\n\r\nok";
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    return;
                }

                if method == "POST" {
                    let stream_id_opt = server.resolve_stream_id(path);
                    let stream_id = match stream_id_opt {
                        Some(id) => id,
                        None => {
                            let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order);
                            let resp = format!(
                                "HTTP/1.1 404 Not Found\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                                msg.len()
                            );
                            let _ = conn.write_all(resp.as_bytes()).await;
                            let _ = conn.flush().await;
                            return;
                        }
                    };

                    while buf.len() < header_end + content_length {
                        match conn.read(&mut tmp).await {
                            Ok(0) | Err(_) => return,
                            Ok(n) => buf.extend_from_slice(&tmp[..n]),
                        }
                    }
                    let body =
                        String::from_utf8_lossy(&buf[header_end..header_end + content_length])
                            .to_string();

                    match server.handle_offer(&stream_id, &body).await {
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
                            let msg = format!("Offer 处理失败 (stream={stream_id}): {e}");
                            let resp = format!(
                                "HTTP/1.1 500 Internal Server Error\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                                msg.len()
                            );
                            let _ = conn.write_all(resp.as_bytes()).await;
                            let _ = conn.flush().await;
                        }
                    }
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

src/main.rs

```rust
pub mod config;
pub mod detector;
pub mod rtsp2frame;
pub mod web_rtc;

use config::{ServerConfig, StreamConfig};
use detector::detect_c_wrapper::DetectCWrapper;
use detector::frame_detector::FrameDetector;
use rtsp2frame::RtspStreamer;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::broadcast;
use web_rtc::{StreamContext, WebRtcServer};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();

    let config_path = if let Some(arg1) = args.get(1) {
        arg1.as_str()
    } else if Path::new("config.yaml").exists() {
        "config.yaml"
    } else if Path::new("config.yml").exists() {
        "config.yml"
    } else {
        eprintln!("[server] 错误: 未指定配置文件且当前目录下未找到 config.yaml / config.yml");
        return Err("未找到配置文件，请传入 yaml 路径或在当前目录放置 config.yaml".into());
    };

    let config = ServerConfig::load_from_file(config_path)
        .map_err(|e| format!("加载配置文件 '{config_path}' 失败: {e}"))?;

    let http_addr = config.http_addr();
    let streams: Vec<StreamConfig> = config.get_streams();

    if streams.is_empty() {
        eprintln!("[server] 错误: 配置文件中未配置任何有效视频流");
        return Err("配置文件中未配置任何视频流 (streams / input)".into());
    }

    println!("==================================================");
    println!("[server] WebRTC 目标检测服务已启动");
    println!("  • 信令监听: http://{}", http_addr);
    for st in &streams {
        println!("  • 视频流 [{}] -> http://{}/{} ({})", st.id, http_addr, st.id, st.input);
    }
    println!("==================================================");

    let detect_wrapper = Arc::new(DetectCWrapper::new());
    let mut stream_contexts = Vec::new();
    let mut streamer_handles = Vec::new();

    for (ch_idx, st) in streams.into_iter().enumerate() {
        let stream_id = st.id.clone();
        let input_url = st.input.clone();
        let (tx_detection, _rx) = broadcast::channel::<String>(256);

        let detector = Arc::new(FrameDetector::with_channel(
            Arc::clone(&detect_wrapper),
            ch_idx as u32,
            stream_id.clone(),
        ));

        let video_track = WebRtcServer::create_video_track(&stream_id);

        let stream_ctx = StreamContext {
            stream_id: stream_id.clone(),
            input_url: input_url.clone(),
            video_track: Arc::clone(&video_track),
            tx_detection: tx_detection.clone(),
        };
        stream_contexts.push(stream_ctx);

        let streamer = RtspStreamer::new(
            stream_id.clone(),
            input_url.clone(),
            Arc::clone(&detector),
            tx_detection,
        );

        let handle = streamer.start_stream(video_track).await?;
        streamer_handles.push(handle);
    }

    let webrtc_server = Arc::new(WebRtcServer::new(&http_addr, stream_contexts));
    webrtc_server.run_signaling_server().await?;

    Ok(())
}
```

build.rs

```rust
use std::env;
use std::fs;

fn link_dylib(so_path: &str) {
    let so_dir = fs::canonicalize(so_path).expect("so file not found");
    let src_dir = so_dir.parent().unwrap();
    let so_file = so_dir.file_name().unwrap().to_str().unwrap();

    println!("cargo:rustc-link-search={}", src_dir.display());
    println!("cargo:rustc-link-arg=-l:{so_file}");
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/lib");
}

fn main() {
    let target = env::var("TARGET").unwrap_or_default();

    if target.contains("aarch64") {
        link_dylib("../c_lib/build/libdetect.so");
    }
}
```

config.yaml

```yaml
input:
  aaa: rtsp://192.168.88.20:8554/file_01
  bbb: rtsp://192.168.88.20:8554/file_02

server:
  host: "0.0.0.0"
  port: 8181
```

build

```sh
cargo build --release --target=aarch64-unknown-linux-gnu
```
