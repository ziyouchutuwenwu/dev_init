use super::stream_context::StreamContext;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use tokio::sync::Mutex;
use webrtc::api::interceptor_registry::register_default_interceptors;
use webrtc::api::media_engine::MediaEngine;
use webrtc::api::APIBuilder;
use webrtc::data_channel::data_channel_state::RTCDataChannelState;
use webrtc::interceptor::registry::Registry;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::peer_connection_state::RTCPeerConnectionState;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use webrtc::peer_connection::RTCPeerConnection;
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

        let conn_id = next_conn_id.fetch_add(1, Ordering::SeqCst);
        active_connections
            .lock()
            .await
            .insert(conn_id, Arc::clone(&pc));
        let pc_monitor = Arc::clone(&pc);
        let connections_ref = Arc::clone(active_connections);

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
        let latest_detection_dc = Arc::clone(&stream_ctx.latest_detection);
        let stream_id_dc = stream_ctx.stream_id.clone();

        pc.on_data_channel(Box::new(move |dc| {
            let tx = tx_for_client_dc.clone();
            let dc_clone = Arc::clone(&dc);
            let latest = Arc::clone(&latest_detection_dc);
            let sid = stream_id_dc.clone();

            Box::pin(async move {
                let started = Arc::new(AtomicBool::new(false));
                let started_clone = Arc::clone(&started);
                let dc_task = Arc::clone(&dc_clone);
                let tx_task = tx.clone();
                let latest_task = Arc::clone(&latest);
                let sid_task = sid.clone();

                let spawn_sender = move || {
                    if !started_clone.swap(true, Ordering::SeqCst) {
                        let dc = Arc::clone(&dc_task);
                        let mut rx = tx_task.subscribe();
                        let latest = Arc::clone(&latest_task);
                        let sid = sid_task.clone();

                        tokio::spawn(async move {
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
                            let _ = dc.send_text(init_payload).await;

                            let mut last_send = std::time::Instant::now();
                            loop {
                                tokio::select! {
                                    res = rx.recv() => {
                                        match res {
                                            Ok(payload) => {
                                                if dc.ready_state() == RTCDataChannelState::Closed {
                                                    break;
                                                }
                                                if dc.ready_state() != RTCDataChannelState::Open {
                                                    continue;
                                                }
                                                if last_send.elapsed() < std::time::Duration::from_millis(60) {
                                                    continue;
                                                }
                                                if dc.buffered_amount().await > 262144 {
                                                    continue;
                                                }
                                                if dc.send_text(payload).await.is_err() {
                                                    break;
                                                }
                                                last_send = std::time::Instant::now();
                                            }
                                            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                                                continue;
                                            }
                                            Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                                                break;
                                            }
                                        }
                                    }
                                    _ = tokio::time::sleep(tokio::time::Duration::from_millis(1000)) => {
                                        if dc.ready_state() == RTCDataChannelState::Closed {
                                            break;
                                        }
                                        if dc.ready_state() == RTCDataChannelState::Open && last_send.elapsed() >= std::time::Duration::from_millis(1000) {
                                            let heartbeat = serde_json::json!({
                                                "id": sid,
                                                "type": "heartbeat",
                                                "timestamp": chrono::Utc::now().timestamp_millis()
                                            })
                                            .to_string();
                                            if dc.send_text(heartbeat).await.is_err() {
                                                break;
                                            }
                                            last_send = std::time::Instant::now();
                                        }
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

                if dc_clone.ready_state() == RTCDataChannelState::Open {
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

        let _ = tokio::time::timeout(
            std::time::Duration::from_millis(600),
            gather_complete.recv(),
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
