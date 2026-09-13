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

    pub async fn run_signaling_server_with_listener(self: Arc<Self>, listener: tokio::net::TcpListener) -> std::io::Result<()> {
        SignalingServer::run_with_listener(self, listener).await
    }
}
