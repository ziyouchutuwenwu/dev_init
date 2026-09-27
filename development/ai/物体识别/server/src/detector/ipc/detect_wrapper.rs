use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use super::ipc_connection::{
    IpcConnection, CMD_CREATE_CHANNEL, CMD_DETECT_LATEST, CMD_FEED_PACKET, CMD_FLUSH_CHANNEL,
    CMD_RELEASE_ALL, CMD_RELEASE_CHANNEL, RESP_DETECT_RESULT, RESP_STATUS,
};

use std::sync::atomic::{AtomicU64, Ordering};

static LAST_SPAWN_TS: AtomicU64 = AtomicU64::new(0);

fn try_spawn_detector() {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let last = LAST_SPAWN_TS.load(Ordering::Relaxed);
    if now.saturating_sub(last) < 3 {
        return;
    }
    if LAST_SPAWN_TS
        .compare_exchange(last, now, Ordering::SeqCst, Ordering::Relaxed)
        .is_err()
    {
        return;
    }

    let candidates = [
        std::path::PathBuf::from("./detector"),
        std::env::current_exe()
            .ok()
            .and_then(|p| p.parent().map(|d| d.join("detector")))
            .unwrap_or_default(),
    ];
    for path in &candidates {
        if path.is_file() {
            log::debug!("[detect_wrapper] 尝试自动拉起算法进程: {}", path.display());
            if let Ok(mut child) = std::process::Command::new(path).spawn() {
                std::thread::spawn(move || {
                    let _ = child.wait();
                });
            }
            std::thread::sleep(Duration::from_millis(300));
            break;
        }
    }
}

#[derive(Clone, Default)]
pub struct DetectWrapper {
    feed_clients: Arc<Mutex<HashMap<u32, Arc<Mutex<IpcConnection>>>>>,
    detect_clients: Arc<Mutex<HashMap<u32, Arc<Mutex<IpcConnection>>>>>,
    control_client: Arc<Mutex<Option<IpcConnection>>>,
}

impl DetectWrapper {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn init_engine(&self) -> Result<(), String> {
        let start = std::time::Instant::now();
        let timeout = Duration::from_secs(6);
        let mut last_err = String::new();
        let mut spawned = false;

        while start.elapsed() < timeout {
            match IpcConnection::connect() {
                Ok(mut conn) => {
                    if conn.ping().is_ok() {
                        let mut ctrl = self.control_client.lock().unwrap();
                        *ctrl = Some(conn);
                        return Ok(());
                    }
                }
                Err(e) => {
                    last_err = e.to_string();
                    if !spawned && start.elapsed() > Duration::from_millis(200) {
                        spawned = true;
                        try_spawn_detector();
                    }
                }
            }
            std::thread::sleep(Duration::from_millis(100));
        }

        Err(format!(
            "连接算法守护进程 (@rk_detector_ipc) 超时: {last_err}"
        ))
    }

    pub fn deinit_engine(&self) -> Result<(), String> {
        let mut ctrl = self.control_client.lock().unwrap();
        *ctrl = None;
        self.feed_clients.lock().unwrap().clear();
        self.detect_clients.lock().unwrap().clear();
        Ok(())
    }

    fn call_simple_cmd(&self, cmd: u8, ch: u32) -> Result<(), String> {
        let mut ctrl = self.control_client.lock().unwrap();
        let conn = match ctrl.as_mut() {
            Some(c) => c,
            None => {
                let new_conn = match IpcConnection::connect() {
                    Ok(c) => c,
                    Err(_) => {
                        try_spawn_detector();
                        std::thread::sleep(Duration::from_millis(200));
                        IpcConnection::connect().map_err(|e| e.to_string())?
                    }
                };
                *ctrl = Some(new_conn);
                ctrl.as_mut().unwrap()
            }
        };

        let payload = ch.to_be_bytes();
        if let Err(e) = conn.send_request(cmd, &payload) {
            *ctrl = None;
            return Err(format!("ipc 发送命令失败: {e}"));
        }

        let (resp_cmd, resp_payload) = match conn.read_response() {
            Ok(r) => r,
            Err(e) => {
                *ctrl = None;
                return Err(format!("ipc 接收响应失败: {e}"));
            }
        };

        if resp_cmd != RESP_STATUS || resp_payload.len() < 4 {
            *ctrl = None;
            return Err(format!("ipc 响应错误: cmd={resp_cmd:#x}"));
        }

        let status = i32::from_be_bytes([
            resp_payload[0],
            resp_payload[1],
            resp_payload[2],
            resp_payload[3],
        ]);
        if status < 0 {
            return Err(format!("算法命令 ({cmd:#x}, ch={ch}) 执行失败: {status}"));
        }
        Ok(())
    }

    pub fn create_channel(&self, ch: u32) -> Result<(), String> {
        self.create_channel_with_codec(ch, "h264")
    }

    pub fn create_channel_with_codec(&self, ch: u32, codec: &str) -> Result<(), String> {
        let mut ctrl = self.control_client.lock().unwrap();
        let conn = match ctrl.as_mut() {
            Some(c) => c,
            None => {
                let new_conn = match IpcConnection::connect() {
                    Ok(c) => c,
                    Err(_) => {
                        try_spawn_detector();
                        std::thread::sleep(Duration::from_millis(200));
                        IpcConnection::connect().map_err(|e| e.to_string())?
                    }
                };
                *ctrl = Some(new_conn);
                ctrl.as_mut().unwrap()
            }
        };

        let mut payload = Vec::with_capacity(4 + codec.len());
        payload.extend_from_slice(&ch.to_be_bytes());
        payload.extend_from_slice(codec.as_bytes());

        if let Err(e) = conn.send_request(CMD_CREATE_CHANNEL, &payload) {
            *ctrl = None;
            return Err(format!("ipc 发送命令失败: {e}"));
        }

        let (resp_cmd, resp_payload) = match conn.read_response() {
            Ok(r) => r,
            Err(e) => {
                *ctrl = None;
                return Err(format!("ipc 接收响应失败: {e}"));
            }
        };

        if resp_cmd != RESP_STATUS || resp_payload.len() < 4 {
            *ctrl = None;
            return Err(format!("ipc 响应错误: cmd={resp_cmd:#x}"));
        }

        let status = i32::from_be_bytes([
            resp_payload[0],
            resp_payload[1],
            resp_payload[2],
            resp_payload[3],
        ]);
        if status < 0 {
            return Err(format!("算法命令 (CREATE_CHANNEL, ch={ch}, codec={codec}) 执行失败: {status}"));
        }
        Ok(())
    }

    pub fn flush_channel(&self, ch: u32) -> Result<(), String> {
        self.call_simple_cmd(CMD_FLUSH_CHANNEL, ch)
    }

    pub fn release_channel(&self, ch: u32) -> Result<(), String> {
        let _ = self.call_simple_cmd(CMD_RELEASE_CHANNEL, ch);
        self.feed_clients.lock().unwrap().remove(&ch);
        self.detect_clients.lock().unwrap().remove(&ch);
        Ok(())
    }

    pub fn create_all(&self, total_streams: u32) -> Result<(), String> {
        self.init_engine()?;
        for ch in 0..total_streams {
            self.create_channel(ch)?;
        }
        Ok(())
    }

    pub fn release_all(&self) -> Result<(), String> {
        let _ = self.call_simple_cmd(CMD_RELEASE_ALL, 0);
        self.deinit_engine()
    }

    pub fn bin_to_img_stream(
        &self,
        ch: u32,
        packet_data: &[u8],
        frame_idx: u64,
        pts_ms: i64,
    ) -> Result<(), String> {
        if packet_data.is_empty() {
            return Ok(());
        }

        let mut payload = Vec::with_capacity(20 + packet_data.len());
        payload.extend_from_slice(&ch.to_be_bytes());
        payload.extend_from_slice(&frame_idx.to_be_bytes());
        payload.extend_from_slice(&pts_ms.to_be_bytes());
        payload.extend_from_slice(packet_data);

        for attempt in 0..2 {
            let client_arc = {
                let map = self.feed_clients.lock().unwrap();
                map.get(&ch).cloned()
            };
            let client_arc = match client_arc {
                Some(c) => c,
                None => {
                    let conn = match IpcConnection::connect() {
                        Ok(c) => c,
                        Err(e) => {
                            if attempt == 0 {
                                try_spawn_detector();
                                std::thread::sleep(Duration::from_millis(200));
                                continue;
                            }
                            return Err(format!("连接送帧通道 (ch={ch}) 失败: {e}"));
                        }
                    };
                    let arc = Arc::new(Mutex::new(conn));
                    let mut map = self.feed_clients.lock().unwrap();
                    map.entry(ch).or_insert(Arc::clone(&arc)).clone()
                }
            };

            let mut conn = client_arc.lock().unwrap();
            if let Err(e) = conn.send_request(CMD_FEED_PACKET, &payload) {
                drop(conn);
                self.feed_clients.lock().unwrap().remove(&ch);
                if attempt == 0 {
                    try_spawn_detector();
                    std::thread::sleep(Duration::from_millis(150));
                    continue;
                }
                return Err(format!("送流失败 (ch={ch}): {e}"));
            }

            match conn.read_response() {
                Ok((resp_cmd, resp_payload)) => {
                    if resp_cmd != RESP_STATUS || resp_payload.len() < 4 {
                        drop(conn);
                        self.feed_clients.lock().unwrap().remove(&ch);
                        return Err(format!("送流响应异常 (ch={ch}): {resp_cmd:#x}"));
                    }
                    let status = i32::from_be_bytes([
                        resp_payload[0],
                        resp_payload[1],
                        resp_payload[2],
                        resp_payload[3],
                    ]);
                    if status < 0 {
                        return Err(format!("vpu 送流返回错误码 (ch={ch}): {status}"));
                    }
                    return Ok(());
                }
                Err(e) => {
                    drop(conn);
                    self.feed_clients.lock().unwrap().remove(&ch);
                    if attempt == 0 {
                        try_spawn_detector();
                        std::thread::sleep(Duration::from_millis(150));
                        continue;
                    }
                    return Err(format!("送流等待响应失败 (ch={ch}): {e}"));
                }
            }
        }

        Err(format!("送流失败 (ch={ch})"))
    }

    pub fn detect_img_bin(&self, ch: u32) -> Result<(Option<String>, u64, i64), String> {
        let payload = ch.to_be_bytes();

        for attempt in 0..2 {
            let client_arc = {
                let map = self.detect_clients.lock().unwrap();
                map.get(&ch).cloned()
            };
            let client_arc = match client_arc {
                Some(c) => c,
                None => {
                    let conn = match IpcConnection::connect() {
                        Ok(c) => c,
                        Err(e) => {
                            if attempt == 0 {
                                try_spawn_detector();
                                std::thread::sleep(Duration::from_millis(200));
                                continue;
                            }
                            return Err(format!("连接检测通道 (ch={ch}) 失败: {e}"));
                        }
                    };
                    let arc = Arc::new(Mutex::new(conn));
                    let mut map = self.detect_clients.lock().unwrap();
                    map.entry(ch).or_insert(Arc::clone(&arc)).clone()
                }
            };

            let mut conn = client_arc.lock().unwrap();
            if let Err(e) = conn.send_request(CMD_DETECT_LATEST, &payload) {
                drop(conn);
                self.detect_clients.lock().unwrap().remove(&ch);
                if attempt == 0 {
                    try_spawn_detector();
                    std::thread::sleep(Duration::from_millis(150));
                    continue;
                }
                return Err(format!("请求检测结果失败 (ch={ch}): {e}"));
            }

            match conn.read_response() {
                Ok((resp_cmd, resp_payload)) => {
                    if resp_cmd != RESP_DETECT_RESULT || resp_payload.len() < 24 {
                        drop(conn);
                        self.detect_clients.lock().unwrap().remove(&ch);
                        return Err(format!("检测响应异常 (ch={ch}): {resp_cmd:#x}"));
                    }

                    let status = i32::from_be_bytes([
                        resp_payload[0],
                        resp_payload[1],
                        resp_payload[2],
                        resp_payload[3],
                    ]);
                    let out_frame_idx = u64::from_be_bytes([
                        resp_payload[4],
                        resp_payload[5],
                        resp_payload[6],
                        resp_payload[7],
                        resp_payload[8],
                        resp_payload[9],
                        resp_payload[10],
                        resp_payload[11],
                    ]);
                    let out_pts_ms = i64::from_be_bytes([
                        resp_payload[12],
                        resp_payload[13],
                        resp_payload[14],
                        resp_payload[15],
                        resp_payload[16],
                        resp_payload[17],
                        resp_payload[18],
                        resp_payload[19],
                    ]);
                    let json_len = u32::from_be_bytes([
                        resp_payload[20],
                        resp_payload[21],
                        resp_payload[22],
                        resp_payload[23],
                    ]) as usize;

                    if status < 0 {
                        return Err(format!("算法检测执行失败 (ch={ch}): {status}"));
                    }

                    if json_len == 0 || resp_payload.len() < 24 + json_len {
                        return Ok((None, out_frame_idx, out_pts_ms));
                    }

                    let json_bytes = &resp_payload[24..24 + json_len];
                    let json_str = String::from_utf8_lossy(json_bytes).into_owned();
                    return Ok((Some(json_str), out_frame_idx, out_pts_ms));
                }
                Err(e) => {
                    drop(conn);
                    self.detect_clients.lock().unwrap().remove(&ch);
                    if attempt == 1 {
                        return Err(format!("读取检测响应失败 (ch={ch}): {e}"));
                    }
                }
            }
        }

        Err(format!("请求检测结果失败 (ch={ch})"))
    }
}
