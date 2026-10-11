use crate::web_rtc::WebRtcServer;
use std::sync::Arc;
use tokio::net::TcpListener;
use super::router::create_router;

pub struct WebServer;

impl WebServer {
    pub async fn run_with_listener(server: Arc<WebRtcServer>, listener: TcpListener) -> std::io::Result<()> {
        let app = create_router(server);
        axum::serve(listener, app).await
    }

    pub async fn run(server: Arc<WebRtcServer>) -> std::io::Result<()> {
        let http_addr = server.http_addr();
        let listener = TcpListener::bind(http_addr).await?;
        Self::run_with_listener(server, listener).await
    }
}
