use super::r#const::*;

pub use super::objects::ZoneConfig;

pub fn to_value(cfg: &ZoneConfig) -> serde_yaml::Value {
    let mut stream_map = serde_yaml::Mapping::new();
    stream_map.insert(
        serde_yaml::Value::String(KEY_ENABLED.into()),
        serde_yaml::Value::Bool(cfg.enabled),
    );
    if let Some(roi) = &cfg.roi
        && let Ok(val) = serde_yaml::to_value(roi)
    {
        stream_map.insert(serde_yaml::Value::String(KEY_ROI.into()), val);
    }
    if let Some(tl) = &cfg.trigger_line
        && let Ok(val) = serde_yaml::to_value(tl)
    {
        stream_map.insert(serde_yaml::Value::String(KEY_TRIGGER_LINE.into()), val);
    }
    serde_yaml::Value::Mapping(stream_map)
}

pub fn to_yaml_value(cfg: &ZoneConfig) -> serde_yaml::Value {
    to_value(cfg)
}
