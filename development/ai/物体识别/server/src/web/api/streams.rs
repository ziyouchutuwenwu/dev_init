use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;
use crate::web_rtc::WebRtcServer;

pub async fn get_streams(State(server): State<Arc<WebRtcServer>>) -> Json<Value> {
    let cfg_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
    let disk_cfg = crate::config::AppConfig::load_from_file(&cfg_path).ok();

    let mut streams_data = Vec::new();
    let mut stream_ids = Vec::new();

    if let Some(cfg) = disk_cfg {
        for s in cfg.input.get_streams() {
            stream_ids.push(s.id.clone());
            streams_data.push(json!({
                "id": s.id,
                "url": s.input,
            }));
        }
    } else {
        for id in server.stream_order() {
            let url = server.get_stream_context(&id).map(|c| c.input_url).unwrap_or_default();
            stream_ids.push(id.clone());
            streams_data.push(json!({
                "id": id,
                "url": url,
            }));
        }
    }

    Json(json!({
        "streams": streams_data,
        "stream_ids": stream_ids,
        "alert_callback_url": crate::updater::get_alert_url(),
        "alert_cooldown_sec": crate::updater::get_alert_cooldown_sec(),
        "alert_timeout_sec": crate::updater::get_alert_timeout_sec(),
    }))
}

pub async fn post_streams(
    State(server): State<Arc<WebRtcServer>>,
    body: String,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let parse_res: Result<(Vec<(String, String)>, Option<String>, Option<u64>, Option<u64>), String> = (|| {
        let v: Value = serde_json::from_str(&body)
            .map_err(|e| format!("json 解析失败: {e}"))?;

        let alert_callback_url = v.get("alert_callback_url")
            .or_else(|| v.get("alert_url"))
            .and_then(|x| x.as_str())
            .map(|s| s.trim().to_string());

        let alert_cooldown_sec = v.get("alert_cooldown_sec")
            .or_else(|| v.get("cooldown_sec"))
            .or_else(|| v.get("cooldown"))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));

        let alert_timeout_sec = v.get("alert_timeout_sec")
            .or_else(|| v.get("timeout_sec"))
            .or_else(|| v.get("timeout"))
            .and_then(|x| x.as_u64().or_else(|| x.as_str().and_then(|s| s.parse::<u64>().ok())));

        let mut streams = Vec::new();
        if let Some(arr) = v.get("streams").and_then(|s| s.as_array()) {
            for item in arr {
                if let Some(obj) = item.as_object() {
                    let id = obj.get("id").or_else(|| obj.get("stream_id")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let url = obj.get("url").or_else(|| obj.get("input")).or_else(|| obj.get("rtsp_url")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    if !id.is_empty() && !url.is_empty() {
                        streams.push((id, url));
                    }
                }
            }
        } else if let Some(map) = v.get("streams").and_then(|s| s.as_object()) {
            for (k, val) in map {
                let id = k.trim().to_string();
                let url = val.as_str().unwrap_or("").trim().to_string();
                if !id.is_empty() && !url.is_empty() {
                    streams.push((id, url));
                }
            }
        } else if let Some(arr) = v.as_array() {
            for item in arr {
                if let Some(obj) = item.as_object() {
                    let id = obj.get("id").or_else(|| obj.get("stream_id")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    let url = obj.get("url").or_else(|| obj.get("input")).or_else(|| obj.get("rtsp_url")).and_then(|x| x.as_str()).unwrap_or("").trim().to_string();
                    if !id.is_empty() && !url.is_empty() {
                        streams.push((id, url));
                    }
                }
            }
        }

        if streams.is_empty() {
            return Err("未包含任何有效的直播流定义 (需包含 id 和 url)".to_string());
        }
        Ok((streams, alert_callback_url, alert_cooldown_sec, alert_timeout_sec))
    })();

    match parse_res {
        Ok((streams_list, alert_url_opt, cooldown_opt, timeout_opt)) => {
            let updated_streams = crate::updater::update_streams(&server, streams_list).await
                .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": e }))))?;

            if alert_url_opt.is_some() || cooldown_opt.is_some() || timeout_opt.is_some() {
                let _ = crate::updater::update_alert_config(
                    alert_url_opt.as_deref(),
                    cooldown_opt,
                    timeout_opt,
                ).await;
            }

            let ret_streams: Vec<_> = updated_streams.iter().map(|(id, url)| {
                json!({ "id": id, "url": url })
            }).collect();

            let current_alert = crate::updater::get_alert_url();
            let current_cooldown = crate::updater::get_alert_cooldown_sec();
            let current_timeout = crate::updater::get_alert_timeout_sec();

            Ok(Json(json!({
                "status": "ok",
                "message": "配置更新成功并已动态热生效",
                "streams": ret_streams,
                "alert_callback_url": current_alert,
                "alert_cooldown_sec": current_cooldown,
                "alert_timeout_sec": current_timeout,
            })))
        }
        Err(err_msg) => {
            Err((
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": err_msg })),
            ))
        }
    }
}
