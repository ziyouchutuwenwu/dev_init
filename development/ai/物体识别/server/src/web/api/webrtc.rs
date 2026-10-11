use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;

pub fn resolve_stream_id(server: &WebRtcServer, path: &str) -> Option<String> {
    if let Some(query_idx) = path.find('?') {
        let query = &path[query_idx + 1..];
        for pair in query.split('&') {
            if let Some((k, v)) = pair.split_once('=') {
                if (k == "src" || k == "stream" || k == "id") && !v.is_empty() {
                    let decoded = v.replace("%2F", "/");
                    if server.has_stream(&decoded) {
                        return Some(decoded);
                    }
                    let lower = decoded.to_lowercase();
                    if server.has_stream(&lower) {
                        return Some(lower);
                    }
                }
            }
        }
    }

    let raw_path = path.split('?').next().unwrap_or(path);
    let raw_path = raw_path.trim_end_matches('/');

    let sub = raw_path.strip_prefix('/').unwrap_or(raw_path);
    if let Some(seg) = sub.strip_prefix("offer/").or_else(|| sub.strip_prefix("api/webrtc/")) {
        if server.has_stream(seg) {
            return Some(seg.to_string());
        }
        let lower = seg.to_lowercase();
        if server.has_stream(&lower) {
            return Some(lower);
        }
    }
    if server.has_stream(sub) {
        return Some(sub.to_string());
    }
    let lower = sub.to_lowercase();
    if server.has_stream(&lower) {
        return Some(lower);
    }
    if sub == "offer" || sub == "webrtc" || sub == "api/webrtc" || sub == "api" || sub.is_empty() {
        return server.default_stream_id();
    }
    None
}

pub async fn handle_offer(
    State(server): State<Arc<WebRtcServer>>,
    Path(stream_id_raw): Path<String>,
    body: String,
) -> Response {
    let stream_id = match resolve_stream_id(&server, &stream_id_raw) {
        Some(id) => id,
        None => {
            let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order());
            return (StatusCode::NOT_FOUND, msg).into_response();
        }
    };

    match server.handle_offer(&stream_id, &body).await {
        Ok(answer_sdp) => {
            (
                StatusCode::OK,
                [("Content-Type", "application/sdp")],
                answer_sdp,
            ).into_response()
        }
        Err(e) => {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("offer 处理失败 (stream={stream_id}): {e}"),
            ).into_response()
        }
    }
}
