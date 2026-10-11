use axum::{
    extract::Path,
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};

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
    Path(stream_id): Path<String>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    match serde_json::from_str::<crate::object_tracker::ZoneConfig>(&body) {
        Ok(new_cfg) => match crate::updater::update_zone(&stream_id, new_cfg).await {
            Ok(saved_cfg) => Ok(Json(json!({"status": "ok", "config": saved_cfg}))),
            Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error": e})))),
        },
        Err(e) => {
            Err((StatusCode::BAD_REQUEST, Json(json!({"error": format!("invalid json format: {e}")}))))
        }
    }
}
