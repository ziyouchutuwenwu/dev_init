use crate::config;
use crate::object_tracker::rules::DetectionRule;
use std::sync::{OnceLock, RwLock};

type DetectionState = Option<(Vec<String>, Vec<DetectionRule>)>;

static GLOBAL_DETECTION_STATE: OnceLock<RwLock<DetectionState>> = OnceLock::new();

fn get_state() -> &'static RwLock<DetectionState> {
    GLOBAL_DETECTION_STATE.get_or_init(|| RwLock::new(None))
}

pub async fn update_detection(
    target_classes: Vec<String>,
    rules: Vec<DetectionRule>,
) -> Result<(), String> {
    if let Ok(mut w) = get_state().write() {
        *w = Some((target_classes.clone(), rules.clone()));
    }

    for ctx in crate::on_detected::ObjectTrackHandler::get_all_contexts() {
        let mut w = ctx.config.write().await;
        w.target_classes = target_classes.clone();
        w.rules = rules.clone();
    }

    config::trigger::save_config(&target_classes, &rules)
        .map_err(|e| format!("保存全局检测配置失败: {e}"))?;

    log::info!(
        "[updater:detection] 成功热更新全局检测类型 ({} 项) 与规则 ({} 项) 并持久化",
        target_classes.len(),
        rules.len()
    );
    Ok(())
}

pub fn get_detection() -> (Vec<String>, Vec<DetectionRule>) {
    if let Ok(guard) = get_state().read()
        && let Some((classes, rules)) = guard.as_ref()
    {
        return (classes.clone(), rules.clone());
    }

    for ctx in crate::on_detected::ObjectTrackHandler::get_all_contexts() {
        if let Ok(r) = ctx.config.try_read()
            && (!r.target_classes.is_empty() || !r.rules.is_empty())
        {
            return (r.target_classes.clone(), r.rules.clone());
        }
    }

    let trig = config::trigger::load_config();
    (trig.target_classes, trig.rules)
}
