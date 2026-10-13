use crate::web_rtc::WebRtcServer;
use std::sync::Arc;

pub async fn update_streams(
    server: &Arc<WebRtcServer>,
    streams_list: Vec<(String, String)>,
) -> Result<Vec<(String, String)>, String> {
    if streams_list.is_empty() {
        return Err("未包含任何有效的直播流定义 (需包含 id 和 url)".to_string());
    }

    let cfg_path = crate::config::get_global_config_path();
    crate::object_tracker::save_input_streams_to_yaml_file(&cfg_path, &streams_list)
        .map_err(|e| format!("写入配置文件失败: {e}"))?;

    log::info!("[updater:streams] 成功保存摄像头配置至 {cfg_path}: {:?}", streams_list);

    if let Err(e) = server.update_streams(streams_list.clone()).await {
        log::error!("[updater:streams] 热更新流状态异常: {e}");
        return Err(format!("热更新流状态异常: {e}"));
    }

    Ok(streams_list)
}
