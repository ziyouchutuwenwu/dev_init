use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;
use crate::config::{KEY_ALERT_CALLBACK_URL, KEY_ALERT_COOLDOWN_SEC, KEY_ALERT_TIMEOUT_SEC, KEY_ALERT_URL};


pub async fn get_streams(State(server): State<Arc<WebRtcServer>>) -> Json<Value> {
    let cfg_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
    let disk_cfg = crate::config::AppConfig::load_from_file(&cfg_path).ok();

    let mut streams_data = Vec::new();
    let mut stream_ids = Vec::new();

    if let Some(cfg) = disk_cfg {
        for s in cfg.input.get_streams() {
            let enabled = server.get_stream_ai_enabled(&s.id).unwrap_or(s.enabled);
            stream_ids.push(s.id.clone());
            streams_data.push(json!({
                "id": s.id,
                "url": s.input,
                "enabled": enabled,
            }));
        }
    } else {
        for id in server.stream_order() {
            let url = server.get_stream_context(&id).map(|c| c.input_url).unwrap_or_default();
            let enabled = server.get_stream_ai_enabled(&id).unwrap_or(true);
            stream_ids.push(id.clone());
            streams_data.push(json!({
                "id": id,
                "url": url,
                "enabled": enabled,
            }));
        }
    }

    let mut resp = serde_json::Map::new();
    resp.insert("streams".to_string(), json!(streams_data));
    resp.insert("stream_ids".to_string(), json!(stream_ids));
    resp.insert(KEY_ALERT_CALLBACK_URL.to_string(), json!(crate::updater::get_alert_url()));
    resp.insert(KEY_ALERT_COOLDOWN_SEC.to_string(), json!(crate::updater::get_alert_cooldown_sec()));
    resp.insert(KEY_ALERT_TIMEOUT_SEC.to_string(), json!(crate::updater::get_alert_timeout_sec()));
    resp.insert("alert".to_string(), json!({
        "url": crate::updater::get_alert_url(),
        "cooldown_sec": crate::updater::get_alert_cooldown_sec(),
        "timeout_sec": crate::updater::get_alert_timeout_sec(),
    }));
    Json(Value::Object(resp))
}

pub fn parse_bool_value(v: Option<&Value>) -> bool {
    match v {
        Some(Value::Bool(b)) => *b,
        Some(Value::String(s)) => {
            let s = s.trim().to_lowercase();
            s != "false" && s != "0" && !s.is_empty()
        }
        Some(Value::Number(n)) => n.as_i64().map(|x| x != 0).unwrap_or(true),
        _ => true,
    }
}

type PostStreamsParsed = (
    Option<Vec<(String, String, bool)>>,
    Option<String>,
    Option<u64>,
    Option<u64>,
);

pub async fn post_streams(
    State(server): State<Arc<WebRtcServer>>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let parse_res: Result<PostStreamsParsed, String> = (|| {
        let v: Value = serde_json::from_str(&body)
            .map_err(|e| format!("json 解析失败: {e}"))?;

        let alert_obj = v.get("alert");
        let alert_callback_url = v.get(KEY_ALERT_CALLBACK_URL)
            .or_else(|| v.get(KEY_ALERT_URL))
            .or_else(|| alert_obj.and_then(|a| a.get("url")))
            .and_then(|x| x.as_str())
            .map(|s| s.trim().to_string());

        let alert_cooldown_sec = v.get(KEY_ALERT_COOLDOWN_SEC)
            .or_else(|| v.get("cooldown_sec"))
            .or_else(|| v.get("cooldown"))
            .or_else(|| alert_obj.and_then(|a| a.get("cooldown_sec")))
            .or_else(|| alert_obj.and_then(|a| a.get("cooldown")))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));

        let alert_timeout_sec = v.get(KEY_ALERT_TIMEOUT_SEC)
            .or_else(|| v.get("timeout_sec"))
            .or_else(|| v.get("timeout"))
            .or_else(|| alert_obj.and_then(|a| a.get("timeout_sec")))
            .or_else(|| alert_obj.and_then(|a| a.get("timeout")))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));

        let mut streams_opt = None;
        if let Some(arr) = v.get("streams").and_then(|s| s.as_array()) {
            let mut list = Vec::new();
            for item in arr {
                if let Some(obj) = item.as_object() {
                    let id = obj.get("id").or_else(|| obj.get("stream_id")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let url = obj.get("url").or_else(|| obj.get("input")).or_else(|| obj.get("rtsp_url")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let enabled = parse_bool_value(obj.get("enabled").or_else(|| obj.get("ai_enabled")));
                    if !id.is_empty() && !url.is_empty() {
                        list.push((id, url, enabled));
                    }
                }
            }
            streams_opt = Some(list);
        } else if let Some(map) = v.get("streams").and_then(|s| s.as_object()) {
            let mut list = Vec::new();
            for (k, val) in map {
                let id = k.trim().to_string();
                let (url, enabled) = if let Some(obj) = val.as_object() {
                    let u = obj.get("url").or_else(|| obj.get("input")).or_else(|| obj.get("rtsp_url")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let en = parse_bool_value(obj.get("enabled").or_else(|| obj.get("ai_enabled")));
                    (u, en)
                } else {
                    (val.as_str().unwrap_or("").trim().to_string(), true)
                };
                if !id.is_empty() && !url.is_empty() {
                    list.push((id, url, enabled));
                }
            }
            streams_opt = Some(list);
        } else if let Some(arr) = v.as_array() {
            let mut list = Vec::new();
            for item in arr {
                if let Some(obj) = item.as_object() {
                    let id = obj.get("id").or_else(|| obj.get("stream_id")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let url = obj.get("url").or_else(|| obj.get("input")).or_else(|| obj.get("rtsp_url")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let enabled = parse_bool_value(obj.get("enabled").or_else(|| obj.get("ai_enabled")));
                    if !id.is_empty() && !url.is_empty() {
                        list.push((id, url, enabled));
                    }
                }
            }
            streams_opt = Some(list);
        }

        if streams_opt.is_none()
            && alert_callback_url.is_none()
            && alert_cooldown_sec.is_none()
            && alert_timeout_sec.is_none()
        {
            return Err("未包含任何有效的直播流定义或告警参数".to_string());
        }

        Ok((streams_opt, alert_callback_url, alert_cooldown_sec, alert_timeout_sec))
    })();

    match parse_res {
        Ok((streams_opt, alert_url_opt, cooldown_opt, timeout_opt)) => {
            let updated_streams = if let Some(streams_list) = streams_opt {
                crate::updater::update_streams(&server, streams_list).await
                    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": e }))))?
            } else {
                server.stream_order().into_iter().map(|id| {
                    let url = server.get_stream_context(&id).map(|c| c.input_url).unwrap_or_default();
                    let enabled = server.get_stream_ai_enabled(&id).unwrap_or(true);
                    (id, url, enabled)
                }).collect()
            };

            if alert_url_opt.is_some() || cooldown_opt.is_some() || timeout_opt.is_some() {
                let _ = crate::updater::update_alert_config(
                    alert_url_opt.as_deref(),
                    cooldown_opt,
                    timeout_opt,
                ).await;
            }

            let ret_streams: Vec<_> = updated_streams.iter().map(|(id, url, enabled)| {
                json!({ "id": id, "url": url, "enabled": enabled })
            }).collect();

            let current_alert = crate::updater::get_alert_url();
            let current_cooldown = crate::updater::get_alert_cooldown_sec();
            let current_timeout = crate::updater::get_alert_timeout_sec();

            let mut obj = serde_json::Map::new();
            obj.insert("status".to_string(), json!("ok"));
            obj.insert("message".to_string(), json!("配置更新成功并已动态热生效"));
            obj.insert("streams".to_string(), json!(ret_streams));
            obj.insert(KEY_ALERT_CALLBACK_URL.to_string(), json!(current_alert));
            obj.insert(KEY_ALERT_COOLDOWN_SEC.to_string(), json!(current_cooldown));
            obj.insert(KEY_ALERT_TIMEOUT_SEC.to_string(), json!(current_timeout));
            obj.insert("alert".to_string(), json!({
                "url": current_alert,
                "cooldown_sec": current_cooldown,
                "timeout_sec": current_timeout,
            }));
            Ok(Json(Value::Object(obj)))
        }
        Err(err_msg) => {
            Err((
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": err_msg })),
            ))
        }
    }
}
