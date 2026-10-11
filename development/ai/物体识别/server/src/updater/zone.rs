use crate::object_tracker::ZoneConfig;

pub async fn update_zone(
    stream_id: &str,
    new_cfg: ZoneConfig,
) -> Result<ZoneConfig, String> {
    let ctx = crate::on_detected::ObjectTrackHandler::get_or_create_context(stream_id, new_cfg.clone());
    {
        let mut w = ctx.config.write().await;
        *w = new_cfg.clone();
    }

    let cfg_path = crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string());
    if let Err(e) = ZoneConfig::save_to_yaml_file(&cfg_path, stream_id, &new_cfg) {
        log::warn!("[updater:zone] 保存流 [{stream_id}] 区域配置到 {cfg_path} 异常: {e}");
    }

    log::info!("[updater:zone] 成功热更新流 [{stream_id}] 触发区域配置并持久化到 {cfg_path}");
    Ok(new_cfg)
}
