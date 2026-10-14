use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Deserialize;
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;

#[derive(Debug, Deserialize, Default)]
pub struct StreamQuery {
    #[serde(alias = "src", alias = "stream", alias = "id")]
    pub stream_id: Option<String>,
}

pub fn resolve_stream_id(server: &WebRtcServer, path: &str) -> Option<String> {
    resolve_stream_id_with_query(server, Some(path), &StreamQuery::default())
}

pub fn resolve_stream_id_with_query(
    server: &WebRtcServer,
    path_opt: Option<&str>,
    query: &StreamQuery,
) -> Option<String> {
    if let Some(ref q_id) = query.stream_id {
        let clean = q_id.trim();
        if !clean.is_empty() {
            if server.has_stream(clean) {
                return Some(clean.to_string());
            }
            let lower = clean.to_lowercase();
            if server.has_stream(&lower) {
                return Some(lower);
            }
            return None;
        }
    }

    if let Some(path) = path_opt {
        if let Some(query_idx) = path.find('?') {
            let q_part = &path[query_idx + 1..];
            for (k, v) in url::form_urlencoded::parse(q_part.as_bytes()) {
                if (k == "src" || k == "stream" || k == "id") && !v.is_empty() {
                    if server.has_stream(&v) {
                        return Some(v.into_owned());
                    }
                    let lower = v.to_lowercase();
                    if server.has_stream(&lower) {
                        return Some(lower);
                    }
                    return None;
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
            return None;
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
        return None;
    }

    server.default_stream_id()
}

pub async fn handle_offer(
    State(server): State<Arc<WebRtcServer>>,
    Path(stream_id_raw): Path<String>,
    Query(query): Query<StreamQuery>,
    body: String,
) -> Response {
    let stream_id = match resolve_stream_id_with_query(&server, Some(&stream_id_raw), &query) {
        Some(id) => id,
        None => {
            let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order());
            return (StatusCode::NOT_FOUND, msg).into_response();
        }
    };

    dispatch_offer(server, stream_id, body).await
}

pub async fn handle_offer_no_path(
    State(server): State<Arc<WebRtcServer>>,
    Query(query): Query<StreamQuery>,
    body: String,
) -> Response {
    let stream_id = match resolve_stream_id_with_query(&server, None, &query) {
        Some(id) => id,
        None => {
            let msg = format!("未找到指定的流。可用流列表: {:?}", server.stream_order());
            return (StatusCode::NOT_FOUND, msg).into_response();
        }
    };

    dispatch_offer(server, stream_id, body).await
}

async fn dispatch_offer(
    server: Arc<WebRtcServer>,
    stream_id: String,
    body: String,
) -> Response {
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
