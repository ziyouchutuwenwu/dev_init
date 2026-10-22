use crate::config::StreamConfig;
use crate::web_rtc::WebRtcServer;
use std::sync::Arc;

pub async fn update_streams(
    server: &Arc<WebRtcServer>,
    streams_list: Vec<StreamConfig>,
) -> Result<Vec<StreamConfig>, String> {

    crate::config::input::save_config(&streams_list)
        .map_err(|e| format!("写入配置文件失败: {e}"))?;

    log::info!("[updater:streams] 成功保存摄像头配置: {:?}", streams_list);

    if let Err(e) = server.update_streams(streams_list.clone()).await {
        log::error!("[updater:streams] 热更新流状态异常: {e}");
        return Err(format!("热更新流状态异常: {e}"));
    }

    Ok(streams_list)
}
