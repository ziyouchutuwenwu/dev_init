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
use webrtc::data_channel::{DataChannel, DataChannelEvent};
use webrtc::media_stream::track_local::TrackLocal;
use webrtc::peer_connection::{
    PeerConnection, PeerConnectionBuilder, PeerConnectionEventHandler,
};

struct ConnectionHandler {
    conn_id: u64,
    active_connections: Arc<Mutex<HashMap<u64, Arc<dyn PeerConnection>>>>,
    gather_complete_tx: tokio::sync::mpsc::Sender<()>,
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
        if matches!(
            state,
            RTCPeerConnectionState::Failed
                | RTCPeerConnectionState::Closed
                | RTCPeerConnectionState::Disconnected
        ) {
            let mut conns = self.active_connections.lock().await;
            conns.remove(&self.conn_id);
        }
    }

    async fn on_data_channel(&self, dc: Arc<dyn DataChannel>) {
        let mut rx = self.tx_detection.subscribe();
        let latest = Arc::clone(&self.latest_detection);
        let sid = self.stream_id.clone();

        tokio::spawn(async move {
            let mut opened = false;
            let mut last_send = std::time::Instant::now();

            loop {
                if opened {
                    tokio::select! {
                        event = dc.poll() => {
                            match event {
                                Some(DataChannelEvent::OnClose) | None => {
                                    break;
                                }
                                _ => {}
                            }
                        }
                        res = rx.recv() => {
                            match res {
                                Ok(payload) => {
                                    if last_send.elapsed() < std::time::Duration::from_millis(60) {
                                        continue;
                                    }
                                    if dc.send_text(&payload).await.is_err() {
                                        break;
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
                                    "timestamp": chrono::Utc::now().timestamp_millis()
                                }).to_string();
                                if dc.send_text(&heartbeat).await.is_err() {
                                    break;
                                }
                                last_send = std::time::Instant::now();
                            }
                        }
                    }
                } else {
                    match dc.poll().await {
                        Some(DataChannelEvent::OnOpen) => {
                            opened = true;
                            let init_payload = {
                                let cache = latest.read().await;
                                match cache.as_ref() {
                                    Some(cached) => cached.clone(),
                                    None => {
                                        let now_ms = chrono::Utc::now().timestamp_millis();
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
                            last_send = std::time::Instant::now();
                        }
                        Some(DataChannelEvent::OnClose) | None => {
                            break;
                        }
                        _ => {}
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

        let handler = Arc::new(ConnectionHandler {
            conn_id,
            active_connections: Arc::clone(active_connections),
            gather_complete_tx,
            tx_detection: stream_ctx.tx_detection.clone(),
            latest_detection: Arc::clone(&stream_ctx.latest_detection),
            stream_id: stream_ctx.stream_id.clone(),
        });

        let config = RTCConfigurationBuilder::new().build();
        let pc: Arc<dyn PeerConnection> = Arc::new(
            PeerConnectionBuilder::new()
                .with_configuration(config)
                .with_media_engine(media_engine)
                .with_interceptor_registry(registry)
                .with_handler(handler)
                .with_udp_addrs(vec!["0.0.0.0:0".to_string()])
                .build()
                .await
                .map_err(|e| e.to_string())?,
        );

        active_connections
            .lock()
            .await
            .insert(conn_id, Arc::clone(&pc));

        let (track, ssrc, payload_type) = StreamContext::create_video_track(&stream_ctx.stream_id)
            .map_err(|e| e.to_string())?;

        pc.add_track(Arc::clone(&track) as Arc<dyn TrackLocal>)
            .await
            .map_err(|e| e.to_string())?;

        let mut rx_video = stream_ctx.tx_video.subscribe();
        let track_forwarder = Arc::clone(&track);
        tokio::spawn(async move {
            loop {
                match rx_video.recv().await {
                    Ok(sample) => {
                        if track_forwarder
                            .sample_writer(ssrc, payload_type)
                            .write_sample(&sample)
                            .await
                            .is_err()
                        {
                            break;
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => break,
                }
            }
        });

        let offer =
            RTCSessionDescription::offer(offer_sdp.to_owned()).map_err(|e| e.to_string())?;
        pc.set_remote_description(offer)
            .await
            .map_err(|e| e.to_string())?;
        let answer = pc.create_answer(None).await.map_err(|e| e.to_string())?;
        pc.set_local_description(answer)
            .await
            .map_err(|e| e.to_string())?;

        let _ = tokio::time::timeout(
            std::time::Duration::from_millis(600),
            gather_complete_rx.recv(),
        )
        .await;

        let sdp = pc
            .local_description()
            .await
            .ok_or_else(|| "本地 sdp 不存在".to_string())?
            .sdp;

        Ok(sdp)
    }
}
