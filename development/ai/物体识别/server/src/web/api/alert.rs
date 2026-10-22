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
    let mut obj = serde_json::Map::new();
    obj.insert("alert_url".to_string(), json!(alert_url));
    obj.insert("alert_callback_url".to_string(), json!(alert_url));
    obj.insert("alert_cooldown_sec".to_string(), json!(cooldown_sec));
    obj.insert("alert_timeout_sec".to_string(), json!(timeout_sec));
    let alert_data = super::objects::AlertObject {
        url: Some(alert_url.clone()),
        cooldown_sec,
        timeout_sec,
    };
    obj.insert("alert".to_string(), json!(alert_data));
    Json(Value::Object(obj))
}

pub async fn post_alert(
    State(_server): State<Arc<WebRtcServer>>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let (url_to_set, cooldown_sec, timeout_sec) = if let Ok(v) = serde_json::from_str::<Value>(&body) {
        let alert_obj = v.get("alert");
        let u = v.get("alert_callback_url")
            .or_else(|| v.get("alert_url"))
            .or_else(|| v.get("url"))
            .or_else(|| alert_obj.and_then(|a| a.get("url")))
            .and_then(|x| x.as_str())
            .map(|s| s.trim().to_string());
        let cd = v.get("alert_cooldown_sec")
            .or_else(|| alert_obj.and_then(|a| a.get("cooldown_sec")))
            .or_else(|| alert_obj.and_then(|a| a.get("cooldown")))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));
        let to = v.get("alert_timeout_sec")
            .or_else(|| alert_obj.and_then(|a| a.get("timeout_sec")))
            .or_else(|| alert_obj.and_then(|a| a.get("timeout")))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));
        (u, cd, to)
    } else {
        let clean = body.trim().trim_matches('"').trim_matches('\'').trim().to_string();
        (Some(clean), None, None)
    };

    match crate::updater::update_alert_config(url_to_set.as_deref(), cooldown_sec, timeout_sec).await {
        Ok(_) => {
            let mut obj = serde_json::Map::new();
            obj.insert("status".to_string(), json!("ok"));
            obj.insert("message".to_string(), json!("告警配置已成功热更新并持久化"));
            obj.insert("alert_url".to_string(), json!(crate::updater::get_alert_url()));
            obj.insert("alert_callback_url".to_string(), json!(crate::updater::get_alert_url()));
            obj.insert("alert_cooldown_sec".to_string(), json!(crate::updater::get_alert_cooldown_sec()));
            obj.insert("alert_timeout_sec".to_string(), json!(crate::updater::get_alert_timeout_sec()));
            let alert_data = super::objects::AlertObject {
                url: Some(crate::updater::get_alert_url()),
                cooldown_sec: crate::updater::get_alert_cooldown_sec(),
                timeout_sec: crate::updater::get_alert_timeout_sec(),
            };
            obj.insert("alert".to_string(), json!(alert_data));
            Ok(Json(Value::Object(obj)))
        }
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": e })),
        )),
    }
}
