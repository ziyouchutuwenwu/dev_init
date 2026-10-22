use axum::{
    routing::{get, post},
    Router,
};
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use crate::web_rtc::WebRtcServer;
use super::api;

pub fn create_router(server: Arc<WebRtcServer>) -> Router {
    let cors = CorsLayer::permissive().allow_private_network(true);

    Router::new()
        .route("/health", get(api::health_check))
        .route("/api/streams", get(api::get_streams).post(api::post_streams))
        .route("/api/zone/{stream_id}", get(api::get_zone).post(api::post_zone))
        .route("/api/detection", get(api::get_detection).post(api::post_detection))
        .route("/api/alert", get(api::get_alert).post(api::post_alert))
        .route("/api/alert_url", get(api::get_alert).post(api::post_alert))
        .route("/offer", post(api::handle_offer_no_path))
        .route("/offer/{stream_id}", post(api::handle_offer))
        .route("/api/webrtc", post(api::handle_offer_no_path))
        .route("/api/webrtc/{stream_id}", post(api::handle_offer))
        .layer(cors)
        .with_state(server)
}
