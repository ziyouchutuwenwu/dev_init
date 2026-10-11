use crate::detector::DetectWrapper;
use crate::web_rtc::{RunningStream, WebRtcServer};
use std::sync::Arc;
use tokio::net::TcpListener;

pub async fn start_webrtc_server(
    http_addr: &str,
    detect_wrapper: Arc<DetectWrapper>,
    initial_streams: Vec<RunningStream>,
) -> Result<(), Box<dyn std::error::Error>> {
    let webrtc_server = Arc::new(WebRtcServer::new(http_addr, detect_wrapper, initial_streams));
    webrtc_server.run_signaling_server().await?;
    Ok(())
}

pub async fn start_webrtc_server_with_listener(
    http_addr: &str,
    detect_wrapper: Arc<DetectWrapper>,
    initial_streams: Vec<RunningStream>,
    listener: TcpListener,
) -> Result<(), Box<dyn std::error::Error>> {
    let webrtc_server = Arc::new(WebRtcServer::new(http_addr, detect_wrapper, initial_streams));
    webrtc_server.run_signaling_server_with_listener(listener).await?;
    Ok(())
}
