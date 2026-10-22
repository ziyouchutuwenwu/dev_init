use super::stream_context::StreamContext;
use rtc::interceptor::Registry;
use rtc::peer_connection::configuration::interceptor_registry::register_default_interceptors;
use rtc::peer_connection::configuration::media_engine::MediaEngine;
use rtc::peer_connection::configuration::RTCConfigurationBuilder;
use rtc::peer_connection::sdp::RTCSessionDescription;
use rtc::peer_connection::state::{RTCIceGatheringState, RTCPeerConnectionState};
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use tokio::sync::Mutex;
use rtc::ice::mdns::MulticastDnsMode;
use rtc::peer_connection::configuration::setting_engine::SettingEngine;
use rtc::peer_connection::transport::RTCDtlsRole;
use webrtc::data_channel::{DataChannel, DataChannelEvent};
use webrtc::media_stream::track_local::TrackLocal;
use webrtc::peer_connection::{
    PeerConnection, PeerConnectionBuilder, PeerConnectionEventHandler,
};

static ACTIVE_STREAM_CONNECTIONS: std::sync::LazyLock<std::sync::Mutex<HashMap<String, usize>>> =
    std::sync::LazyLock::new(|| std::sync::Mutex::new(HashMap::new()));

pub fn is_stream_connected(stream_id: &str) -> bool {
    let map = ACTIVE_STREAM_CONNECTIONS.lock().unwrap();
    map.get(stream_id).copied().unwrap_or(0) > 0
}

pub fn add_stream_connection(stream_id: &str) {
    let mut map = ACTIVE_STREAM_CONNECTIONS.lock().unwrap();
    *map.entry(stream_id.to_string()).or_insert(0) += 1;
}

pub fn remove_stream_connection(stream_id: &str) {
    let mut map = ACTIVE_STREAM_CONNECTIONS.lock().unwrap();
    if let Some(count) = map.get_mut(stream_id) {
        if *count > 0 {
            *count -= 1;
        }
    }
}

struct ConnectionHandler {
    conn_id: u64,
    active_connections: Arc<Mutex<HashMap<u64, Arc<dyn PeerConnection>>>>,
    gather_complete_tx: tokio::sync::mpsc::Sender<()>,
    connected_notify: Arc<tokio::sync::Notify>,
    is_connected: Arc<std::sync::atomic::AtomicBool>,
    conn_counted: Arc<std::sync::atomic::AtomicBool>,
    stop_tx: tokio::sync::broadcast::Sender<()>,
    tx_detection: tokio::sync::broadcast::Sender<String>,
    latest_detection: Arc<tokio::sync::RwLock<Option<String>>>,
    stream_id: String,
}

#[async_trait::async_trait]
impl PeerConnectionEventHandler for ConnectionHandler {
    async fn on_ice_gathering_state_change(&self, state: RTCIceGatheringState) {
        if state == RTCIceGatheringState::Complete {
            let _ = self.gather_complete_tx.try_send(());
        }
    }

    async fn on_connection_state_change(&self, state: RTCPeerConnectionState) {
        if state == RTCPeerConnectionState::Connected {
            self.is_connected.store(true, Ordering::SeqCst);
            if !self.conn_counted.swap(true, Ordering::SeqCst) {
                add_stream_connection(&self.stream_id);
            }
            self.connected_notify.notify_waiters();
        } else if matches!(
            state,
            RTCPeerConnectionState::Failed
                | RTCPeerConnectionState::Closed
                | RTCPeerConnectionState::Disconnected
        ) {
            self.is_connected.store(false, Ordering::SeqCst);
            if self.conn_counted.swap(false, Ordering::SeqCst) {
                remove_stream_connection(&self.stream_id);
            }
            let _ = self.stop_tx.send(());
            let active_conns = Arc::clone(&self.active_connections);
            let conn_id = self.conn_id;
            tokio::spawn(async move {
                let pc_opt = {
                    let mut conns = active_conns.lock().await;
                    conns.remove(&conn_id)
                };
                if let Some(pc) = pc_opt {
                    let _ = pc.close().await;
                }
            });
        }
    }

    async fn on_data_channel(&self, dc: Arc<dyn DataChannel>) {
        let mut rx = self.tx_detection.subscribe();
        let mut stop_rx = self.stop_tx.subscribe();
        let mut dc_stop_rx = self.stop_tx.subscribe();
        let latest = Arc::clone(&self.latest_detection);
        let sid = self.stream_id.clone();

        tokio::spawn(async move {
            let (close_tx, mut close_rx) = tokio::sync::mpsc::channel::<()>(1);
            let (open_tx, mut open_rx) = tokio::sync::mpsc::channel::<()>(1);

            let dc_event_listener = Arc::clone(&dc);
            tokio::spawn(async move {
                loop {
                    tokio::select! {
                        _ = dc_stop_rx.recv() => {
                            break;
                        }
                        evt = dc_event_listener.poll() => {
                            match evt {
                                Some(DataChannelEvent::OnOpen) => {
                                    let _ = open_tx.try_send(());
                                }
                                Some(DataChannelEvent::OnClose) => {
                                    let _ = close_tx.try_send(());
                                    break;
                                }
                                Some(_) => {}
                                None => {
                                    let _ = close_tx.try_send(());
                                    break;
                                }
                            }
                        }
                    }
                }
            });

            let _ = tokio::time::timeout(std::time::Duration::from_millis(1500), open_rx.recv()).await;

            let init_payload = {
                let cache = latest.read().await;
                match cache.as_ref() {
                    Some(cached) => cached.clone(),
                    None => {
                        let now_ms = crate::current_time_millis();
                        serde_json::json!({
                            "id": sid,
                            "type": "heartbeat",
                            "timestamp": now_ms
                        })
                        .to_string()
                    }
                }
            };
            let _ = dc.send_text(&init_payload).await;

            let mut last_send = std::time::Instant::now();

            loop {
                tokio::select! {
                    _ = stop_rx.recv() => {
                        log::info!("[peer_manager:{sid}] 收到 peer_connection 断开信号，退出 data_channel 协程");
                        break;
                    }
                    _ = close_rx.recv() => {
                        log::info!("[peer_manager:{sid}] 收到 data_channel 关闭事件，退出发送协程");
                        break;
                    }
                    res = rx.recv() => {
                        match res {
                            Ok(payload) => {
                                if last_send.elapsed() < std::time::Duration::from_millis(20) {
                                    continue;
                                }
                                if let Err(e) = dc.send_text(&payload).await {
                                    log::debug!("[peer_manager:{sid}] data_channel 发送暂缓: {e}");
                                    tokio::time::sleep(std::time::Duration::from_millis(30)).await;
                                    continue;
                                }
                                last_send = std::time::Instant::now();
                            }
                            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                            Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                        }
                    }
                    _ = tokio::time::sleep(std::time::Duration::from_millis(1000)) => {
                        if last_send.elapsed() >= std::time::Duration::from_millis(1000) {
                            let heartbeat = serde_json::json!({
                                "id": sid,
                                "type": "heartbeat",
                                "timestamp": crate::current_time_millis()
                            }).to_string();
                            let _ = dc.send_text(&heartbeat).await;
                            last_send = std::time::Instant::now();
                        }
                    }
                }
            }
        });
    }
}

pub struct PeerManager;

impl PeerManager {
    pub async fn handle_offer(
        stream_ctx: &StreamContext,
        offer_sdp: &str,
        active_connections: &Arc<Mutex<HashMap<u64, Arc<dyn PeerConnection>>>>,
        next_conn_id: &AtomicU64,
    ) -> Result<String, String> {
        let mut media_engine = MediaEngine::default();
        media_engine
            .register_default_codecs()
            .map_err(|e| e.to_string())?;
        let registry = register_default_interceptors(Registry::new(), &mut media_engine)
            .map_err(|e| e.to_string())?;

        let conn_id = next_conn_id.fetch_add(1, Ordering::SeqCst);
        let (gather_complete_tx, mut gather_complete_rx) = tokio::sync::mpsc::channel::<()>(1);
        let (stop_tx, _) = tokio::sync::broadcast::channel::<()>(4);
        let connected_notify = Arc::new(tokio::sync::Notify::new());
        let is_connected = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let is_connected_video = Arc::clone(&is_connected);
        let conn_counted = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let conn_counted_video = Arc::clone(&conn_counted);

        let handler = Arc::new(ConnectionHandler {
            conn_id,
            active_connections: Arc::clone(active_connections),
            gather_complete_tx,
            connected_notify: Arc::clone(&connected_notify),
            is_connected,
            conn_counted,
            stop_tx: stop_tx.clone(),
            tx_detection: stream_ctx.tx_detection.clone(),
            latest_detection: Arc::clone(&stream_ctx.latest_detection),
            stream_id: stream_ctx.stream_id.clone(),
        });

        let mut setting_engine = SettingEngine::default();
        setting_engine.set_multicast_dns_mode(MulticastDnsMode::Disabled);
        setting_engine.set_lite(true);
        setting_engine
            .set_answering_dtls_role(RTCDtlsRole::Server)
            .map_err(|e| e.to_string())?;

        let config = RTCConfigurationBuilder::new().build();
        let pc: Arc<dyn PeerConnection> = Arc::new(
            PeerConnectionBuilder::new()
                .with_configuration(config)
                .with_setting_engine(setting_engine)
                .with_media_engine(media_engine)
                .with_interceptor_registry(registry)
                .with_handler(handler)
                .with_udp_addrs(vec!["0.0.0.0:0".to_string()])
                .build()
                .await
                .map_err(|e| e.to_string())?,
        );

        let (track, ssrc, payload_type) = match StreamContext::create_video_track(&stream_ctx.stream_id) {
            Ok(res) => res,
            Err(e) => {
                let _ = pc.close().await;
                return Err(e.to_string());
            }
        };

        if let Err(e) = pc.add_track(Arc::clone(&track) as Arc<dyn TrackLocal>).await {
            let _ = pc.close().await;
            return Err(e.to_string());
        }

        let json_extracted;
        let actual_sdp = if offer_sdp.trim_start().starts_with('{') {
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(offer_sdp) {
                if let Some(sdp_str) = val.get("sdp").and_then(|s| s.as_str()) {
                    json_extracted = sdp_str.to_string();
                    json_extracted.as_str()
                } else {
                    offer_sdp
                }
            } else {
                offer_sdp
            }
        } else {
            offer_sdp
        };

        let cleaned_sdp: String = actual_sdp
            .lines()
            .filter(|line| !line.starts_with("a=candidate:") || !line.contains(".local"))
            .collect::<Vec<_>>()
            .join("\r\n")
            + "\r\n";

        let offer = match RTCSessionDescription::offer(cleaned_sdp) {
            Ok(o) => o,
            Err(e) => {
                let _ = pc.close().await;
                return Err(e.to_string());
            }
        };

        if let Err(e) = pc.set_remote_description(offer).await {
            let _ = pc.close().await;
            return Err(e.to_string());
        }

        let answer = match pc.create_answer(None).await {
            Ok(a) => a,
            Err(e) => {
                let _ = pc.close().await;
                return Err(e.to_string());
            }
        };

        if let Err(e) = pc.set_local_description(answer).await {
            let _ = pc.close().await;
            return Err(e.to_string());
        }

        let _ = tokio::time::timeout(
            std::time::Duration::from_millis(600),
            gather_complete_rx.recv(),
        )
        .await;

        let sdp = match pc.local_description().await {
            Some(desc) => desc.sdp,
            None => {
                let _ = pc.close().await;
                return Err("本地 sdp 不存在".to_string());
            }
        };

        active_connections
            .lock()
            .await
            .insert(conn_id, Arc::clone(&pc));

        let mut rx_video = stream_ctx.tx_video.subscribe();
        let mut stop_rx = stop_tx.subscribe();
        let stop_tx_clone = stop_tx.clone();
        let track_forwarder = Arc::clone(&track);
        let connected_notify_clone = Arc::clone(&connected_notify);
        let active_connections_video = Arc::clone(active_connections);
        let pc_video_cleanup = Arc::clone(&pc);
        let stream_id_video = stream_ctx.stream_id.clone();

        tokio::spawn(async move {
            let notified = connected_notify_clone.notified();
            let connected = if is_connected_video.load(Ordering::SeqCst) {
                true
            } else {
                tokio::select! {
                    _ = stop_rx.recv() => false,
                    _ = notified => true,
                    _ = tokio::time::sleep(std::time::Duration::from_secs(10)) => {
                        is_connected_video.load(Ordering::SeqCst)
                    }
                }
            };

            if !connected {
                let _ = pc_video_cleanup.close().await;
                if conn_counted_video.swap(false, Ordering::SeqCst) {
                    remove_stream_connection(&stream_id_video);
                }
                let mut conns = active_connections_video.lock().await;
                conns.remove(&conn_id);
                return;
            }

            tokio::time::sleep(std::time::Duration::from_millis(60)).await;

            let mut received_keyframe = false;
            let stream_start_time = std::time::Instant::now();
            let mut video_errors = 0;
            loop {
                tokio::select! {
                    _ = stop_rx.recv() => {
                        log::info!("[peer_manager] 连接已关闭，退出视频推流协程");
                        break;
                    }
                    sample_res = rx_video.recv() => {
                        match sample_res {
                            Ok(sample) => {
                                if !is_connected_video.load(Ordering::Relaxed) {
                                    continue;
                                }
                                if !received_keyframe {
                                    if is_video_keyframe(&sample.data) || stream_start_time.elapsed() > std::time::Duration::from_secs(3) {
                                        received_keyframe = true;
                                        log::info!("[peer_manager:{conn_id}] 捕获到首个视频关键帧，开始推流");
                                    } else {
                                        continue;
                                    }
                                }
                                if let Err(e) = track_forwarder
                                    .sample_writer(ssrc, payload_type)
                                    .write_sample(&sample)
                                    .await
                                {
                                    video_errors += 1;
                                    if video_errors > 30 {
                                        log::warn!("[peer_manager] 视频推流连续错误超限({e})，断开该客户端连接");
                                        let _ = stop_tx_clone.send(());
                                        break;
                                    }
                                    tokio::time::sleep(std::time::Duration::from_millis(20)).await;
                                    continue;
                                }
                                video_errors = 0;
                            }
                            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                            Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                        }
                    }
                }
            }

            let _ = pc_video_cleanup.close().await;
            if conn_counted_video.swap(false, Ordering::SeqCst) {
                remove_stream_connection(&stream_id_video);
            }
            let mut conns = active_connections_video.lock().await;
            conns.remove(&conn_id);
        });

        Ok(sdp)
    }
}

pub fn is_h264_keyframe(data: &[u8]) -> bool {
    use h264_reader::annexb::AnnexBReader;
    use h264_reader::nal::{Nal, RefNal, UnitType};
    use h264_reader::push::NalInterest;

    let mut is_key = false;
    let mut reader = AnnexBReader::accumulate(|nal: RefNal<'_>| {
        if let Ok(header) = nal.header() {
            let t = header.nal_unit_type();
            if t == UnitType::SeqParameterSet || t == UnitType::SliceLayerWithoutPartitioningIdr {
                is_key = true;
            }
        }
        NalInterest::Ignore
    });
    reader.push(data);
    reader.push(&[0, 0, 0, 1]);
    is_key
}

pub fn is_h265_keyframe(data: &[u8]) -> bool {
    let len = data.len();
    if len < 5 {
        return false;
    }
    let mut i = 0;
    while i + 4 <= len {
        let mut nal_offset = 0;
        if data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 1 {
            nal_offset = i + 3;
        } else if data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 0 && data[i + 3] == 1 {
            nal_offset = i + 4;
        }
        if nal_offset > 0 && nal_offset < len {
            let b0 = data[nal_offset];
            if (b0 & 0x80) == 0 {
                let nal_type = (b0 >> 1) & 0x3F;
                if matches!(nal_type, 19 | 20 | 21 | 32 | 33 | 34) {
                    return true;
                }
            }
            i = nal_offset;
            continue;
        }
        i += 1;
    }
    false
}

pub fn is_video_keyframe(data: &[u8]) -> bool {
    if is_h264_keyframe(data) {
        return true;
    }
    is_h265_keyframe(data)
}
