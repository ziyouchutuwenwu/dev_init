use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;

pub async fn get_zone(Path(stream_id): Path<String>) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    if let Some(ctx) = crate::on_detected::ObjectTrackHandler::get_context(&stream_id) {
        let cfg = ctx.config.read().await.clone();
        Ok(Json(json!({
            "stream_id": stream_id,
            "config": cfg,
        })))
    } else {
        Err((StatusCode::NOT_FOUND, Json(json!({"error": "stream not found"}))))
    }
}

pub async fn post_zone(
    State(server): State<Arc<WebRtcServer>>,
    Path(stream_id): Path<String>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let val: Value = match serde_json::from_str(&body) {
        Ok(v) => v,
        Err(e) => return Err((StatusCode::BAD_REQUEST, Json(json!({"error": format!("invalid json format: {e}")})))),
    };

    let target_enabled = if let Some(en_val) = val.get("enabled").or_else(|| val.get("ai_enabled")) {
        crate::web::api::streams::parse_bool_value(Some(en_val))
    } else {
        server.get_stream_ai_enabled(&stream_id).unwrap_or(true)
    };

    let mut new_cfg: crate::object_tracker::ZoneConfig = match serde_json::from_value(val) {
        Ok(c) => c,
        Err(e) => return Err((StatusCode::BAD_REQUEST, Json(json!({"error": format!("invalid zone config: {e}")})))),
    };
    new_cfg.enabled = target_enabled;

    match crate::updater::update_zone(&stream_id, new_cfg.clone()).await {
        Ok(saved_cfg) => {
            if let Some(current_ai) = server.get_stream_ai_enabled(&stream_id) {
                if current_ai != new_cfg.enabled {
                    let streams: Vec<(String, String, bool)> = server.stream_order().into_iter().map(|id| {
                        let url = server.get_stream_context(&id).map(|c| c.input_url).unwrap_or_default();
                        let en = if id == stream_id { new_cfg.enabled } else { server.get_stream_ai_enabled(&id).unwrap_or(true) };
                        (id, url, en)
                    }).collect();
                    let _ = server.update_streams(streams).await;
                }
            }
            Ok(Json(json!({"status": "ok", "config": saved_cfg})))
        }
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error": e})))),
    }
}
