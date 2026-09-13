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
