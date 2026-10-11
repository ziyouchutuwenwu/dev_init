use crate::web_rtc::WebRtcServer;
use std::sync::Arc;
use tokio::net::TcpListener;

pub struct SignalingServer;

impl SignalingServer {
    pub fn resolve_stream_id(server: &WebRtcServer, path: &str) -> Option<String> {
        crate::web::api::webrtc::resolve_stream_id(server, path)
    }

    pub async fn run_with_listener(server: Arc<WebRtcServer>, listener: TcpListener) -> std::io::Result<()> {
        crate::web::WebServer::run_with_listener(server, listener).await
    }

    pub async fn run(server: Arc<WebRtcServer>) -> std::io::Result<()> {
        crate::web::WebServer::run(server).await
    }
}
