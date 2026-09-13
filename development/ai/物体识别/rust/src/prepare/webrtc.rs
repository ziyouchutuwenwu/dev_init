use crate::web_rtc::{StreamContext, WebRtcServer};
use std::sync::Arc;
use tokio::net::TcpListener;

pub async fn start_webrtc_server(
    http_addr: &str,
    stream_contexts: Vec<StreamContext>,
) -> Result<(), Box<dyn std::error::Error>> {
    let webrtc_server = Arc::new(WebRtcServer::new(http_addr, stream_contexts));
    webrtc_server.run_signaling_server().await?;
    Ok(())
}

pub async fn start_webrtc_server_with_listener(
    http_addr: &str,
    stream_contexts: Vec<StreamContext>,
    listener: TcpListener,
) -> Result<(), Box<dyn std::error::Error>> {
    let webrtc_server = Arc::new(WebRtcServer::new(http_addr, stream_contexts));
    webrtc_server.run_signaling_server_with_listener(listener).await?;
    Ok(())
}
