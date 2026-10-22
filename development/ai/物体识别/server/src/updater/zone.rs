use crate::config::{channel, ZoneConfig};

pub async fn update_zone(
    stream_id: &str,
    new_cfg: ZoneConfig,
) -> Result<ZoneConfig, String> {
    let ctx = crate::on_detected::ObjectTrackHandler::get_or_create_context(stream_id, new_cfg.clone());
    {
        let mut w = ctx.config.write().await;
        *w = new_cfg.clone();
    }

    if let Err(e) = channel::save_config(stream_id, &new_cfg) {
        log::warn!("[updater:zone] 保存流 [{stream_id}] 通道配置异常: {e}");
    }

    log::info!("[updater:zone] 成功热更新流 [{stream_id}] 通道配置并持久化");
    Ok(new_cfg)
}
