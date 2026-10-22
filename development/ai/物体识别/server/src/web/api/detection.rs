use axum::{http::StatusCode, Json};
use serde_json::{json, Value};
use super::objects::DetectionObject;

pub async fn get_detection() -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let (classes, rules) = crate::updater::get_detection();
    let obj = DetectionObject {
        target_classes: classes,
        rules,
    };
    Ok(Json(serde_json::to_value(obj).unwrap_or_default()))
}

pub async fn post_detection(body: String) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let obj: DetectionObject = match serde_json::from_str(&body) {
        Ok(v) => v,
        Err(e) => return Err((StatusCode::BAD_REQUEST, Json(json!({"error": format!("invalid json format: {e}")})))),
    };

    match crate::updater::update_detection(obj.target_classes.clone(), obj.rules.clone()).await {
        Ok(_) => Ok(Json(json!({
            "status": "ok",
            "target_classes": obj.target_classes,
            "rules": obj.rules,
        }))),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error": e})))),
    }
}
