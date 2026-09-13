# rust

## 说明

rust 调用 rknn 的 so

## 步骤

### 依赖

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

### 代码

src/config/base/section.rs

```rust
use std::collections::HashMap;

#[derive(Debug, Clone, Default)]
pub struct ConfigSection {
    pub(crate) values: HashMap<String, String>,
    pub(crate) children: HashMap<String, ConfigSection>,
    pub(crate) items: Vec<String>,
}

impl ConfigSection {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert_value(&mut self, key: String, value: String) {
        self.values.insert(key, value);
    }

    pub fn get_str(&self, key: &str) -> Option<&str> {
        match self.values.get(key) {
            Some(v) => Some(v.as_str()),
            None => None,
        }
    }

    pub fn get_string(&self, key: &str) -> Option<String> {
        match self.values.get(key) {
            Some(v) => Some(v.clone()),
            None => None,
        }
    }

    pub fn get_u16(&self, key: &str) -> Option<u16> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<u16>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn get_u64(&self, key: &str) -> Option<u64> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<u64>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn get_f64(&self, key: &str) -> Option<f64> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<f64>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn remove_value(&mut self, key: &str) -> Option<String> {
        self.values.remove(key)
    }

    pub fn contains_value(&self, key: &str) -> bool {
        self.values.contains_key(key)
    }

    pub fn values(&self) -> &HashMap<String, String> {
        &self.values
    }

    pub fn insert_child(&mut self, name: String, child: ConfigSection) {
        self.children.insert(name, child);
    }

    pub fn get_child(&self, name: &str) -> Option<&ConfigSection> {
        self.children.get(name)
    }

    pub fn get_child_mut(&mut self, name: &str) -> Option<&mut ConfigSection> {
        self.children.get_mut(name)
    }

    pub fn remove_child(&mut self, name: &str) -> Option<ConfigSection> {
        self.children.remove(name)
    }

    pub fn contains_child(&self, name: &str) -> bool {
        self.children.contains_key(name)
    }

    pub fn children(&self) -> &HashMap<String, ConfigSection> {
        &self.children
    }

    pub fn add_item(&mut self, item: String) {
        self.items.push(item);
    }

    pub fn items(&self) -> &[String] {
        &self.items
    }

    pub fn clear(&mut self) {
        self.values.clear();
        self.children.clear();
        self.items.clear();
    }
}
```

src/config/base/parser.rs

```rust
use std::collections::HashMap;
use std::path::Path;
use super::section::ConfigSection;

#[derive(Debug, Clone, Default)]
pub struct ConfigParser {
    pub(crate) sections: HashMap<String, ConfigSection>,
}

impl ConfigParser {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(&path)?;
        Self::from_str(&content)
    }

    pub fn from_str(content: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let mut sections: HashMap<String, ConfigSection> = HashMap::new();
        let mut current_sec_name = String::new();
        let mut current_child_name = String::new();
        let mut current_grand_name = String::new();

        for line_raw in content.lines() {
            let line_no_comment = match line_raw.find('#') {
                Some(idx) => &line_raw[..idx],
                None => line_raw,
            };
            let line_trimmed = line_no_comment.trim();
            if line_trimmed.is_empty() {
                continue;
            }

            let mut indent = 0;
            for c in line_no_comment.chars() {
                if c.is_whitespace() {
                    indent += 1;
                } else {
                    break;
                }
            }

            if indent == 0 && line_trimmed.ends_with(':') {
                current_sec_name = line_trimmed.trim_end_matches(':').trim().to_lowercase();
                current_child_name.clear();
                current_grand_name.clear();
                if !sections.contains_key(&current_sec_name) {
                    sections.insert(current_sec_name.clone(), ConfigSection::new());
                }
                continue;
            }

            if current_sec_name.is_empty() {
                continue;
            }

            let sec = match sections.get_mut(&current_sec_name) {
                Some(s) => s,
                None => continue,
            };

            if line_trimmed.starts_with("- ") {
                let val = match line_trimmed.strip_prefix("- ") {
                    Some(v) => v.trim().trim_matches('"').trim_matches('\'').trim().to_string(),
                    None => String::new(),
                };
                if !val.is_empty() {
                    sec.add_item(val);
                }
                continue;
            }

            if line_trimmed.ends_with(':') {
                let name = line_trimmed.trim_end_matches(':').trim().to_lowercase();
                if current_child_name.is_empty() || indent <= 2 {
                    current_child_name = name;
                    current_grand_name.clear();
                    if !sec.contains_child(&current_child_name) {
                        sec.insert_child(current_child_name.clone(), ConfigSection::new());
                    }
                } else {
                    current_grand_name = name;
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        if !child_sec.contains_child(&current_grand_name) {
                            child_sec.insert_child(current_grand_name.clone(), ConfigSection::new());
                        }
                    }
                }
                continue;
            }

            if let Some((k, v)) = line_trimmed.split_once(':') {
                let k = k.trim().trim_matches('"').trim_matches('\'').trim().to_lowercase();
                let v = v.trim().trim_matches('"').trim_matches('\'').trim().to_string();
                if k.is_empty() || v.is_empty() {
                    continue;
                }

                if !current_grand_name.is_empty() {
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        if let Some(grand_sec) = child_sec.get_child_mut(&current_grand_name) {
                            grand_sec.insert_value(k, v);
                            continue;
                        }
                    }
                }

                if !current_child_name.is_empty() {
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        child_sec.insert_value(k, v);
                        continue;
                    }
                }

                sec.insert_value(k, v);
            }
        }

        Ok(Self { sections })
    }

    pub fn insert_section(&mut self, name: String, section: ConfigSection) {
        self.sections.insert(name, section);
    }

    pub fn get_section(&self, name: &str) -> Option<&ConfigSection> {
        self.sections.get(name)
    }

    pub fn get_section_mut(&mut self, name: &str) -> Option<&mut ConfigSection> {
        self.sections.get_mut(name)
    }

    pub fn remove_section(&mut self, name: &str) -> Option<ConfigSection> {
        self.sections.remove(name)
    }

    pub fn contains_section(&self, name: &str) -> bool {
        self.sections.contains_key(name)
    }

    pub fn sections(&self) -> &HashMap<String, ConfigSection> {
        &self.sections
    }
}
```

src/config/base/mod.rs

```rust
pub mod parser;
pub mod section;

pub use parser::ConfigParser;
pub use section::ConfigSection;
```

src/config/app/app.rs

```rust
use super::input::InputConfig;
use super::server::ServerConfig;
use super::trigger::TriggerConfig;
use crate::config::base::ConfigParser;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub input: InputConfig,
    pub server: ServerConfig,
    #[serde(default)]
    pub trigger: Option<TriggerConfig>,
}

impl AppConfig {
    pub fn load_from_file<P: AsRef<std::path::Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let parser = ConfigParser::from_file(&path)?;

        let input_sec = parser.get_section("input");
        let input = InputConfig::from_section(input_sec)?;

        let server_sec = parser.get_section("server");
        let server = ServerConfig::from_section(server_sec);

        let trigger_sec = parser.get_section("trigger");
        let trigger = TriggerConfig::from_section(trigger_sec);

        Ok(Self {
            input,
            server,
            trigger,
        })
    }
}
```

src/config/app/input.rs

```rust
use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InputConfig {
    pub streams: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StreamConfig {
    pub id: String,
    pub input: String,
}

impl InputConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Result<Self, String> {
        let sec = match section {
            Some(s) => s,
            None => return Err("未在配置文件中找到 input 配置段".to_string()),
        };

        let mut streams = HashMap::new();
        for (k, v) in sec.values() {
            if !k.is_empty() && !v.is_empty() {
                streams.insert(k.clone(), v.clone());
            }
        }

        if streams.is_empty() {
            return Err("未在配置文件中找到任何有效的视频流定义".to_string());
        }

        Ok(Self { streams })
    }

    pub fn get_streams(&self) -> Vec<StreamConfig> {
        let mut sorted_keys: Vec<&String> = self.streams.keys().collect();
        sorted_keys.sort();
        sorted_keys
            .into_iter()
            .map(|k| StreamConfig {
                id: k.clone(),
                input: self.streams[k].clone(),
            })
            .collect()
    }
}
```

src/config/app/server.rs

```rust
use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

impl ServerConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Self {
        let sec = match section {
            Some(s) => s,
            None => {
                return Self {
                    host: "0.0.0.0".to_string(),
                    port: 8181,
                };
            }
        };

        let host = sec.get_string("host").unwrap_or_else(|| "0.0.0.0".to_string());
        let port = sec.get_u16("port").unwrap_or(8181);

        Self { host, port }
    }

    pub fn http_addr(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}
```

src/config/app/trigger.rs

```rust
use crate::config::base::ConfigSection;
use crate::config::trigger::ModbusRule;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct TriggerConfig {
    #[serde(default)]
    pub modbus: HashMap<String, ModbusRule>,
}

impl TriggerConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Option<Self> {
        let sec = section?;
        let modbus_sec = sec.get_child("modbus")?;

        let mut modbus = HashMap::new();
        for (target_name, target_sec) in modbus_sec.children() {
            modbus.insert(
                target_name.clone(),
                ModbusRule::from_section(target_sec),
            );
        }

        if modbus.is_empty() {
            None
        } else {
            Some(Self { modbus })
        }
    }
}
```

src/config/trigger/modbus.rs

```rust
use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ModbusRule {
    pub coil: u16,
    pub frozon_duration: u64,
    pub min_confidence: f64,
}

impl ModbusRule {
    pub fn from_section(section: &ConfigSection) -> Self {
        let coil = section.get_u16("coil").unwrap_or(0);
        let frozon_duration = section.get_u64("frozon_duration").unwrap_or(3);
        let min_confidence = section.get_f64("min_confidence").unwrap_or(0.5);

        Self {
            coil,
            frozon_duration,
            min_confidence,
        }
    }
}
```

src/config/trigger/mod.rs

```rust
pub mod modbus;
pub use modbus::ModbusRule;
```

src/config/mod.rs

```rust
pub mod app;
pub mod base;
pub mod trigger;

pub use app::{AppConfig, InputConfig, ServerConfig, StreamConfig, TriggerConfig};
pub use base::{ConfigParser, ConfigSection};
pub use trigger::ModbusRule;
```

src/detector/c/unsafe.rs

```rust
use std::os::raw::{c_char, c_int, c_uchar};

unsafe extern "C" {
    pub fn init(total_streams: c_int) -> c_int;

    pub fn bin_to_img_stream(
        ch: c_int,
        packet_data: *const c_uchar,
        packet_size: c_int,
        frame_idx: u64,
        pts_ms: i64,
    ) -> c_int;

    pub fn detect_img_bin(
        ch: c_int,
        out_buf: *mut c_char,
        out_buf_size: c_int,
        out_frame_idx: *mut u64,
        out_pts_ms: *mut i64,
    ) -> c_int;
}
```

src/detector/c/detect_wrapper.rs

```rust
use std::ffi::CStr;
use std::os::raw::{c_char, c_int};
use super::r#unsafe::{bin_to_img_stream, detect_img_bin, init};

#[derive(Default, Debug, Clone, Copy)]
pub struct DetectWrapper;

pub type DetectCWrapper = DetectWrapper;

impl DetectWrapper {
    pub fn new() -> Self {
        Self
    }

    pub fn init(&self, total_streams: u32) -> Result<(), String> {
        unsafe {
            let ret = init(total_streams as c_int);
            if ret < 0 {
                return Err(format!("init failed with code: {ret}"));
            }
            Ok(())
        }
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

src/detector/c/mod.rs

```rust
pub mod detect_wrapper;
pub mod r#unsafe;

pub use detect_wrapper::{DetectCWrapper, DetectWrapper};
```

src/detector/frame_detector.rs

```rust
use std::sync::Arc;
use super::DetectCWrapper;
use super::detection_result::DetectionResult;

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

    pub fn detect_latest(&self) -> Result<DetectionResult, String> {
        let (raw_json, out_frame_idx, out_pts_ms) = self.detect_wrapper.detect_img_bin(self.channel_id)?;
        let parsed = match serde_json::from_str::<serde_json::Value>(&raw_json) {
            Ok(v) => v,
            Err(_) => serde_json::Value::Array(Vec::new()),
        };

        let mut frame_w = Some(self.default_width);
        let mut frame_h = Some(self.default_height);
        let mut f_idx = out_frame_idx;
        let mut f_pts = out_pts_ms;
        let mut detections = Vec::new();

        if let serde_json::Value::Object(map) = parsed {
            if let Some(w) = parse_dimension(map.get("frame_width")) {
                frame_w = Some(w);
            }
            if let Some(h) = parse_dimension(map.get("frame_height")) {
                frame_h = Some(h);
            }
            if let Some(idx) = parse_u64(map.get("frame_idx")) {
                f_idx = idx;
            }
            if let Some(pts) = parse_i64(map.get("pts_ms")) {
                f_pts = pts;
            }
            if let Some(serde_json::Value::Array(arr)) = map.get("detections") {
                detections = arr.clone();
            }
        }

        let fw_f = match frame_w {
            Some(w) => w as f64,
            None => self.default_width as f64,
        };
        let fh_f = match frame_h {
            Some(h) => h as f64,
            None => self.default_height as f64,
        };

        for detection in &mut detections {
            normalize_detection_box(detection, fw_f, fh_f);
        }

        Ok(DetectionResult {
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

fn parse_dimension(val: Option<&serde_json::Value>) -> Option<i32> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    match num.as_i64() {
        Some(v) if v > 0 => Some(v as i32),
        _ => None,
    }
}

fn parse_u64(val: Option<&serde_json::Value>) -> Option<u64> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    num.as_u64()
}

fn parse_i64(val: Option<&serde_json::Value>) -> Option<i64> {
    let num = match val {
        Some(serde_json::Value::Number(n)) => n,
        _ => return None,
    };
    num.as_i64()
}

fn normalize_detection_box(detection: &mut serde_json::Value, fw_f: f64, fh_f: f64) {
    let det_obj = match detection {
        serde_json::Value::Object(map) => map,
        _ => return,
    };

    if det_obj.contains_key("rel_box") {
        return;
    }

    let box_arr = match det_obj.get("box") {
        Some(serde_json::Value::Array(arr)) if arr.len() >= 4 => arr,
        _ => return,
    };

    let x1 = match box_arr[0].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let y1 = match box_arr[1].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let x2 = match box_arr[2].as_f64() {
        Some(v) => v,
        None => 0.0,
    };
    let y2 = match box_arr[3].as_f64() {
        Some(v) => v,
        None => 0.0,
    };

    if x1 <= 1.0 && y1 <= 1.0 && x2 <= 1.0 && y2 <= 1.0 && (x2 > 0.0 || y2 > 0.0) {
        det_obj.insert("rel_box".to_string(), serde_json::json!([x1, y1, x2, y2]));
        return;
    }

    if fw_f > 0.0 && fh_f > 0.0 {
        let rx1 = (x1 / fw_f).clamp(0.0, 1.0);
        let ry1 = (y1 / fh_f).clamp(0.0, 1.0);
        let rx2 = (x2 / fw_f).clamp(0.0, 1.0);
        let ry2 = (y2 / fh_f).clamp(0.0, 1.0);
        det_obj.insert("rel_box".to_string(), serde_json::json!([rx1, ry1, rx2, ry2]));
    }
}
```

src/detector/detection_result.rs

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionObject {
    pub class_id: Option<i32>,
    pub label: Option<String>,
    pub confidence: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rel_box: Option<Vec<f64>>,
    pub box_coord: Vec<f64>,
}

pub type DetectionItem = DetectionObject;


#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionResult {
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

impl DetectionResult {
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
pub mod c;
pub mod detection_result;
pub mod frame_detector;

pub use c::{DetectCWrapper, DetectWrapper};
pub use detection_result::{DetectionItem, DetectionObject, DetectionResult};
pub use frame_detector::FrameDetector;
```

src/on_detected/dispatcher.rs

```rust
use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct DetectedDispatcher {
    sender: broadcast::Sender<Arc<DetectionResult>>,
}

impl DetectedDispatcher {
    pub fn new() -> Self {
        Self::with_capacity(128)
    }

    pub fn with_capacity(capacity: usize) -> Self {
        let (sender, _) = broadcast::channel(capacity);
        Self { sender }
    }

    pub fn subscribe(&self) -> broadcast::Receiver<Arc<DetectionResult>> {
        self.sender.subscribe()
    }

    pub fn publish(&self, result: Arc<DetectionResult>) {
        let _ = self.sender.send(result);
    }
}

impl Default for DetectedDispatcher {
    fn default() -> Self {
        Self::new()
    }
}
```

src/on_detected/modbus_handler.rs

```rust
use crate::config::ModbusRule;
use crate::detector::detection_result::DetectionResult;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::broadcast;

pub struct ModbusHandler;

impl ModbusHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        rules: Option<HashMap<String, ModbusRule>>,
    ) {
        tokio::spawn(loop_check(stream_id.into(), receiver, rules));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    rules: Option<HashMap<String, ModbusRule>>,
) {
    println!("[on_detected:modbus:{stream_id}] 订阅协程已启动，等待检测目标事件...");

    let mut last_alarm_times: HashMap<String, Instant> = HashMap::new();

    loop {
        match receiver.recv().await {
            Ok(result) => {
                for detection in &result.detections {
                    let label = match detection.get("label") {
                        Some(serde_json::Value::String(s)) => s.clone(),
                        _ => continue,
                    };

                    let confidence = match detection.get("confidence") {
                        Some(serde_json::Value::Number(n)) => match n.as_f64() {
                            Some(v) => v,
                            None => 0.0,
                        },
                        _ => 0.0,
                    };

                    let (coil, frozon_duration, min_confidence) = match &rules {
                        Some(map) => match map.get(&label) {
                            Some(rule) => (
                                rule.coil,
                                Duration::from_secs(rule.frozon_duration),
                                rule.min_confidence,
                            ),
                            None => continue,
                        },
                        None => (0, Duration::from_secs(3), 0.5),
                    };

                    if confidence < min_confidence {
                        continue;
                    }

                    let should_alarm = match last_alarm_times.get(&label) {
                        Some(time) => time.elapsed() >= frozon_duration,
                        None => true,
                    };

                    if should_alarm {
                        last_alarm_times.insert(label.clone(), Instant::now());
                        println!(
                            "[on_detected:modbus:{stream_id}] ⚡ 触发 Modbus 信号! 类型: {label}, 线圈(coil): {coil}, 置信度: {confidence:.2}"
                        );
                    }
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => {}
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }

    println!("[on_detected:modbus:{stream_id}] 订阅协程已退出");
}
```

src/on_detected/webrtc_handler.rs

```rust
use crate::detector::detection_result::DetectionResult;
use std::sync::Arc;
use tokio::sync::broadcast;

pub struct WebRtcHandler;

impl WebRtcHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        tx_broadcast: broadcast::Sender<String>,
    ) {
        tokio::spawn(loop_check(
            stream_id.into(),
            receiver,
            tx_broadcast,
        ));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    tx_broadcast: broadcast::Sender<String>,
) {
    log::info!("[on_detected:webrtc:{stream_id}] 订阅协程已启动");
    loop {
        match receiver.recv().await {
            Ok(result) => {
                if let Ok(json_msg) = serde_json::to_string(&*result) {
                    let _ = tx_broadcast.send(json_msg);
                }
            }
            Err(broadcast::error::RecvError::Lagged(skipped)) => {
                log::warn!("[on_detected:webrtc:{stream_id}] 消费过慢，丢弃了 {skipped} 帧检测结果");
            }
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }
    log::info!("[on_detected:webrtc:{stream_id}] 订阅协程已退出");
}
```

src/prepare/config.rs

```rust
use std::path::Path;

pub fn resolve_config_path() -> Result<String, Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if let Some(arg) = args.get(1) {
        return Ok(arg.clone());
    }
    if Path::new("config.yaml").exists() {
        return Ok("config.yaml".to_string());
    }
    if Path::new("config.yml").exists() {
        return Ok("config.yml".to_string());
    }
    Err("未找到配置文件 config.yaml".into())
}
```

src/prepare/stream.rs

```rust
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
    };

    let dispatcher = Arc::new(DetectedDispatcher::new());
    WebRtcHandler::start(&stream_id, dispatcher.subscribe(), tx_detection);
    ModbusHandler::start(&stream_id, dispatcher.subscribe(), modbus_rules);

    let streamer = RtspStreamer::new(
        stream_id,
        input_url,
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
```

src/prepare/webrtc.rs

```rust
use crate::web_rtc::{StreamContext, WebRtcServer};
use std::sync::Arc;

pub async fn start_webrtc_server(
    http_addr: &str,
    stream_contexts: Vec<StreamContext>,
) -> Result<(), Box<dyn std::error::Error>> {
    let webrtc_server = Arc::new(WebRtcServer::new(http_addr, stream_contexts));
    webrtc_server.run_signaling_server().await?;
    Ok(())
}
```

src/prepare/mod.rs

```rust
pub mod config;
pub mod stream;
pub mod webrtc;

pub use config::resolve_config_path;
pub use stream::{init_detector, setup_single_stream, start_all_streams};
pub use webrtc::start_webrtc_server;
```

src/rtsp2frame/h264_utils.rs

```rust
pub struct H264Utils;

impl H264Utils {
    pub fn to_annex_b(input: &[u8]) -> Vec<u8> {
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
            let len = u32::from_be_bytes([
                input[offset],
                input[offset + 1],
                input[offset + 2],
                input[offset + 3],
            ]) as usize;
            if len == 0 || offset + 4 + len > input.len() {
                is_valid_avcc = false;
                break;
            }
            out.extend_from_slice(&[0x00, 0x00, 0x00, 0x01]);
            out.extend_from_slice(&input[offset + 4..offset + 4 + len]);
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
}
```

src/rtsp2frame/rtsp_streamer.rs

```rust
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
                eprintln!("[rtsp:{stream_id}] describe 失败: {e}，5秒后重试");
                tokio::time::sleep(Duration::from_secs(5)).await;
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
                let sps_pps_annexb = H264Utils::to_annex_b(extra);
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
```

src/rtsp2frame/mod.rs

```rust
pub mod h264_utils;
pub mod rtsp_streamer;

pub use h264_utils::H264Utils;
pub use rtsp_streamer::RtspStreamer;
```

src/web_rtc/peer_manager.rs

```rust
use super::stream_context::StreamContext;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use tokio::sync::Mutex;
use webrtc::api::interceptor_registry::register_default_interceptors;
use webrtc::api::media_engine::MediaEngine;
use webrtc::api::APIBuilder;
use webrtc::data_channel::data_channel_state::RTCDataChannelState;
use webrtc::data_channel::RTCDataChannel;
use webrtc::interceptor::registry::Registry;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::peer_connection_state::RTCPeerConnectionState;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use webrtc::peer_connection::RTCPeerConnection;
use webrtc::rtp_transceiver::rtp_sender::RTCRtpSender;
use webrtc::track::track_local::TrackLocal;

pub struct PeerManager;

impl PeerManager {
    pub async fn handle_offer(
        stream_ctx: &StreamContext,
        offer_sdp: &str,
        active_connections: &Arc<Mutex<HashMap<u64, Arc<RTCPeerConnection>>>>,
        next_conn_id: &AtomicU64,
    ) -> Result<String, String> {
        let mut m = MediaEngine::default();
        m.register_default_codecs().map_err(to_str_err)?;
        let mut registry = Registry::new();
        registry = register_default_interceptors(registry, &mut m).map_err(to_str_err)?;
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
                .map_err(to_str_err)?,
        );

        let conn_id = next_conn_id.fetch_add(1, Ordering::SeqCst);
        active_connections
            .lock()
            .await
            .insert(conn_id, Arc::clone(&pc));

        let pc_monitor = Arc::clone(&pc);
        let connections_ref = Arc::clone(active_connections);
        pc.on_peer_connection_state_change(Box::new(move |s| {
            let pc = Arc::clone(&pc_monitor);
            let conns = Arc::clone(&connections_ref);
            Box::pin(handle_pc_state_change(s, conns, pc))
        }));

        let sender = pc
            .add_track(Arc::clone(&stream_ctx.video_track) as Arc<dyn TrackLocal + Send + Sync>)
            .await
            .map_err(to_str_err)?;

        tokio::spawn(drain_sender(sender));

        let tx_for_client_dc = stream_ctx.tx_detection.clone();
        pc.on_data_channel(Box::new(move |dc| {
            let tx = tx_for_client_dc.clone();
            Box::pin(handle_incoming_data_channel(dc, tx))
        }));

        let offer = RTCSessionDescription::offer(offer_sdp.to_owned()).map_err(to_str_err)?;
        pc.set_remote_description(offer)
            .await
            .map_err(to_str_err)?;
        let answer = pc.create_answer(None).await.map_err(to_str_err)?;
        let mut gather_complete = pc.gathering_complete_promise().await;
        pc.set_local_description(answer)
            .await
            .map_err(to_str_err)?;

        let _ = tokio::time::timeout(
            std::time::Duration::from_millis(1500),
            gather_complete.recv(),
        )
        .await;

        let local_desc = match pc.local_description().await {
            Some(desc) => desc,
            None => return Err("本地 sdp 不存在".to_string()),
        };
        Ok(local_desc.sdp)
    }
}

fn to_str_err<E: std::fmt::Display>(e: E) -> String {
    e.to_string()
}

async fn drain_sender(sender: Arc<RTCRtpSender>) {
    let mut b = vec![0u8; 1500];
    while sender.read(&mut b).await.is_ok() {}
}

async fn handle_pc_state_change(
    state: RTCPeerConnectionState,
    connections: Arc<Mutex<HashMap<u64, Arc<RTCPeerConnection>>>>,
    pc: Arc<RTCPeerConnection>,
) {
    if matches!(
        state,
        RTCPeerConnectionState::Failed
            | RTCPeerConnectionState::Closed
            | RTCPeerConnectionState::Disconnected
    ) {
        let mut map = connections.lock().await;
        let mut to_remove = Vec::new();
        for (id, conn) in map.iter() {
            if Arc::ptr_eq(conn, &pc) {
                to_remove.push(*id);
            }
        }
        for id in to_remove {
            map.remove(&id);
        }
    }
}

async fn forward_detection_to_dc(
    dc: Arc<RTCDataChannel>,
    mut rx: tokio::sync::broadcast::Receiver<String>,
) {
    loop {
        match rx.recv().await {
            Ok(payload) => {
                if dc.send_text(payload).await.is_err() {
                    break;
                }
            }
            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
            Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
        }
    }
}

async fn handle_incoming_data_channel(
    dc: Arc<RTCDataChannel>,
    tx_detection: tokio::sync::broadcast::Sender<String>,
) {
    let started = Arc::new(AtomicBool::new(false));
    let dc_for_open = Arc::clone(&dc);
    let started_for_open = Arc::clone(&started);
    let tx_for_open = tx_detection.clone();

    dc.on_open(Box::new(move || {
        let dc = Arc::clone(&dc_for_open);
        let tx = tx_for_open.clone();
        let started = Arc::clone(&started_for_open);
        Box::pin(start_forwarding_if_needed(started, dc, tx))
    }));

    if dc.ready_state() == RTCDataChannelState::Open {
        start_forwarding_if_needed(started, dc, tx_detection).await;
    }
}

async fn start_forwarding_if_needed(
    started: Arc<AtomicBool>,
    dc: Arc<RTCDataChannel>,
    tx_detection: tokio::sync::broadcast::Sender<String>,
) {
    if !started.swap(true, Ordering::SeqCst) {
        let rx = tx_detection.subscribe();
        tokio::spawn(forward_detection_to_dc(dc, rx));
    }
}
```

src/web_rtc/signaling_server.rs

```rust
use super::WebRtcServer;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

pub struct SignalingServer;

impl SignalingServer {
    pub fn resolve_stream_id(server: &WebRtcServer, path: &str) -> Option<String> {
        if let Some(query_idx) = path.find('?') {
            let query = &path[query_idx + 1..];
            for pair in query.split('&') {
                if let Some((k, v)) = pair.split_once('=') {
                    if (k == "src" || k == "stream" || k == "id") && !v.is_empty() {
                        let decoded = v.replace("%2F", "/");
                        if server.streams().contains_key(&decoded) {
                            return Some(decoded);
                        }
                    }
                }
            }
        }

        let raw_path = match path.split('?').next() {
            Some(p) => p,
            None => path,
        };
        let raw_path = raw_path.trim_end_matches('/');

        let sub = match raw_path.strip_prefix('/') {
            Some(s) => s,
            None => raw_path,
        };
        if let Some(seg) = sub.strip_prefix("offer/") {
            if server.streams().contains_key(seg) {
                return Some(seg.to_string());
            }
        }
        if !sub.is_empty() && sub != "health" && sub != "streams" && sub != "api" {
            if server.streams().contains_key(sub) {
                return Some(sub.to_string());
            }
            return Some(sub.to_string());
        }

        server.default_stream_id().cloned()
    }

    pub async fn run(server: Arc<WebRtcServer>) -> std::io::Result<()> {
        let listener = TcpListener::bind(server.http_addr()).await?;

        loop {
            let (conn, _) = listener.accept().await?;
            let server = Arc::clone(&server);
            tokio::spawn(Self::handle_connection(server, conn));
        }
    }

    async fn handle_connection(server: Arc<WebRtcServer>, mut conn: TcpStream) {
        let mut buf: Vec<u8> = Vec::new();
        let mut tmp = [0u8; 4096];
        let header_end = loop {
            let n = match conn.read(&mut tmp).await {
                Ok(0) | Err(_) => return,
                Ok(n) => n,
            };
            buf.extend_from_slice(&tmp[..n]);
            if let Some(pos) = find_header_end(&buf) {
                break pos;
            }
            if buf.len() > (1 << 20) {
                return;
            }
        };

        let headers = String::from_utf8_lossy(&buf[..header_end]);
        let first_line = match headers.lines().next() {
            Some(l) => l,
            None => "",
        };
        let mut parts = first_line.split_whitespace();
        let method = match parts.next() {
            Some(m) => m,
            None => "",
        };
        let path = match parts.next() {
            Some(p) => p,
            None => "",
        };

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
            let content_length = match parse_content_length(&headers) {
                Some(len) if len > 0 => len,
                _ => {
                    let msg = "POST 请求必须包含有效的 Content-Length 且长度大于 0";
                    let resp = format!(
                        "HTTP/1.1 400 Bad Request\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n\r\n{msg}",
                        msg.len()
                    );
                    let _ = conn.write_all(resp.as_bytes()).await;
                    let _ = conn.flush().await;
                    return;
                }
            };

            let stream_id_opt = Self::resolve_stream_id(&server, path);
            let stream_id = match stream_id_opt {
                Some(id) => id,
                None => {
                    let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order());
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
                String::from_utf8_lossy(&buf[header_end..header_end + content_length]).to_string();

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
    }
}

fn find_header_end(buf: &[u8]) -> Option<usize> {
    if buf.len() < 4 {
        return None;
    }
    for i in 0..=buf.len() - 4 {
        if &buf[i..i + 4] == b"\r\n\r\n" {
            return Some(i + 4);
        }
    }
    None
}

fn parse_content_length(headers: &str) -> Option<usize> {
    for line in headers.lines() {
        let trimmed = line.trim();
        let lower = trimmed.to_ascii_lowercase();
        if let Some(val) = lower.strip_prefix("content-length:") {
            return val.trim().parse::<usize>().ok();
        }
    }
    None
}
```

src/web_rtc/stream_context.rs

```rust
use std::sync::Arc;
use tokio::sync::broadcast;
use webrtc::rtp_transceiver::rtp_codec::RTCRtpCodecCapability;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

#[derive(Clone)]
pub struct StreamContext {
    pub stream_id: String,
    pub input_url: String,
    pub video_track: Arc<TrackLocalStaticSample>,
    pub tx_detection: broadcast::Sender<String>,
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
```

src/web_rtc/web_rtc_server.rs

```rust
use super::peer_manager::PeerManager;
use super::signaling_server::SignalingServer;
use super::stream_context::StreamContext;
use std::collections::HashMap;
use std::sync::atomic::AtomicU64;
use std::sync::Arc;
use tokio::sync::Mutex;
use webrtc::peer_connection::RTCPeerConnection;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

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
        StreamContext::create_video_track(stream_id)
    }

    pub fn new(http_addr: impl Into<String>, stream_contexts: Vec<StreamContext>) -> Self {
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

    pub fn http_addr(&self) -> &str {
        &self.http_addr
    }

    pub fn streams(&self) -> &HashMap<String, StreamContext> {
        &self.streams
    }

    pub fn stream_order(&self) -> &[String] {
        &self.stream_order
    }

    pub fn default_stream_id(&self) -> Option<&String> {
        self.default_stream_id.as_ref()
    }

    pub async fn handle_offer(&self, stream_id: &str, offer_sdp: &str) -> Result<String, String> {
        let stream_ctx = match self.streams.get(stream_id) {
            Some(ctx) => ctx,
            None => {
                return Err(format!(
                    "未找到指定的流 ID '{}'。当前已加载的可用流: {:?}",
                    stream_id, self.stream_order
                ));
            }
        };

        PeerManager::handle_offer(
            stream_ctx,
            offer_sdp,
            &self.active_connections,
            &self.next_conn_id,
        )
        .await
    }

    pub async fn run_signaling_server(self: Arc<Self>) -> std::io::Result<()> {
        SignalingServer::run(self).await
    }
}
```

src/web_rtc/mod.rs

```rust
pub mod peer_manager;
pub mod signaling_server;
pub mod stream_context;
pub mod web_rtc_server;

pub use peer_manager::PeerManager;
pub use signaling_server::SignalingServer;
pub use stream_context::StreamContext;
pub use web_rtc_server::WebRtcServer;
```

src/main.rs

```rust
pub mod config;
pub mod detector;
pub mod on_detected;
pub mod prepare;
pub mod rtsp2frame;
pub mod web_rtc;

use config::AppConfig;
use prepare::{init_detector, resolve_config_path, start_all_streams, start_webrtc_server};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config_path = resolve_config_path()?;
    let config = AppConfig::load_from_file(config_path)?;
    let streams = config.input.get_streams();
    if streams.is_empty() {
        return Err("配置文件未包含有效视频流".into());
    }

    let http_addr = config.server.http_addr();

    let detect_wrapper = init_detector(streams.len());
    let modbus_rules = match &config.trigger {
        Some(t) => Some(t.modbus.clone()),
        None => None,
    };

    let (stream_contexts, _streamer_handles) =
        start_all_streams(streams, detect_wrapper, modbus_rules).await?;

    start_webrtc_server(&http_addr, stream_contexts).await
}
```

### 配置

config.yaml

```yaml
input:
  aaa: rtsp://192.168.88.20:8554/file_01
  bbb: rtsp://192.168.88.20:8554/file_02

server:
  host: "0.0.0.0"
  port: 8181

trigger:
  modbus:
    person:
      coil: 1
      frozon_duration: 3
      min_confidence: 0.6
    car:
      coil: 2
      frozon_duration: 10
      min_confidence: 0.5
    fire:
      coil: 3
      frozon_duration: 60
      min_confidence: 0.75
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
        link_dylib("../rknn/rknn_lib/build/libdetect.so");
    }
}
```

build.sh

```sh
#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "${SCRIPT_DIR}"

RUSTFLAGS="-C link-arg=-Wl,--allow-shlib-undefined" cargo build --release --target=aarch64-unknown-linux-gnu
```
