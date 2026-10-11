use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;

pub async fn get_alert(State(_server): State<Arc<WebRtcServer>>) -> Json<Value> {
    let alert_url = crate::updater::get_alert_url();
    let cooldown_sec = crate::updater::get_alert_cooldown_sec();
    let timeout_sec = crate::updater::get_alert_timeout_sec();
    Json(json!({
        "alert_url": alert_url,
        "alert_callback_url": alert_url,
        "alert_cooldown_sec": cooldown_sec,
        "alert_timeout_sec": timeout_sec,
    }))
}

pub async fn post_alert(
    State(_server): State<Arc<WebRtcServer>>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let (url_to_set, cooldown_sec, timeout_sec) = if let Ok(v) = serde_json::from_str::<Value>(&body) {
        let u = v.get("alert_callback_url")
            .or_else(|| v.get("alert_url"))
            .or_else(|| v.get("url"))
            .and_then(|x| x.as_str())
            .map(|s| s.trim().to_string());
        let cd = v.get("alert_cooldown_sec")
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));
        let to = v.get("alert_timeout_sec")
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));
        (u, cd, to)
    } else {
        let clean = body.trim().trim_matches('"').trim_matches('\'').trim().to_string();
        (Some(clean), None, None)
    };

    match crate::updater::update_alert_config(url_to_set.as_deref(), cooldown_sec, timeout_sec).await {
        Ok(_) => Ok(Json(json!({
            "status": "ok",
            "message": "告警配置已成功热更新并持久化",
            "alert_url": crate::updater::get_alert_url(),
            "alert_callback_url": crate::updater::get_alert_url(),
            "alert_cooldown_sec": crate::updater::get_alert_cooldown_sec(),
            "alert_timeout_sec": crate::updater::get_alert_timeout_sec(),
        }))),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": e })),
        )),
    }
}
