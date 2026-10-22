use crate::object_tracker::rules::DetectionRule;
use crate::object_tracker::zone::{CrossingDirection, RoiConfig, ZoneLineConfig};
use serde_yaml::Value;
use std::collections::HashMap;
use std::io;
use super::r#const::*;
use super::YamlConfig;

pub use super::objects::ZoneConfig;

pub fn load_config(stream_id: &str) -> ZoneConfig {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml(&cfg, stream_id)
}

pub fn save_config(stream_id: &str, cfg: &ZoneConfig) -> io::Result<()> {
    let path = super::get_config_path();
    let mut config = YamlConfig::load_or_default(&path);
    apply_to_yaml(stream_id, cfg, &mut config);
    config.save()
}

pub fn load_all() -> HashMap<String, ZoneConfig> {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml_all(&cfg)
}

pub fn from_yaml(cfg: &YamlConfig, stream_id: &str) -> ZoneConfig {
    let stream_val = match cfg.get_nested(&[KEY_TRIGGER, stream_id]) {
        Some(v) => v,
        None => return ZoneConfig::default(),
    };

    let enabled = stream_val
        .get(KEY_ENABLED)
        .and_then(|v| v.as_bool())
        .unwrap_or(true);

    let mut roi = None;
    if let Some(roi_val) = stream_val.get(KEY_ROI) {
        if let Ok(r) = serde_yaml::from_value::<RoiConfig>(roi_val.clone()) {
            roi = Some(r);
        } else if let Some(roi_str) = roi_val.as_str()
            && let Ok(r) = serde_json::from_str::<RoiConfig>(roi_str)
        {
            roi = Some(r);
        }
    }

    let mut trigger_line = None;
    let line_opt = stream_val
        .get(KEY_TRIGGER_LINE)
        .or_else(|| stream_val.get(KEY_TRIGGER_AREA));
    if let Some(line_val) = line_opt {
        if let Ok(line_cfg) = serde_yaml::from_value::<ZoneLineConfig>(line_val.clone()) {
            trigger_line = Some(line_cfg);
        } else {
            let parsed_line = serde_yaml::from_value::<[[f64; 2]; 2]>(line_val.clone())
                .ok()
                .or_else(|| {
                    line_val
                        .as_str()
                        .and_then(|s| serde_json::from_str::<[[f64; 2]; 2]>(s).ok())
                });
            if let Some(line) = parsed_line {
                let dir_str = stream_val
                    .get(KEY_DIRECTION)
                    .and_then(|v| v.as_str())
                    .unwrap_or_default();
                let direction = match dir_str.to_lowercase().as_str() {
                    KEY_FORWARD => CrossingDirection::Forward,
                    KEY_BACKWARD => CrossingDirection::Backward,
                    _ => CrossingDirection::Any,
                };
                trigger_line = Some(ZoneLineConfig { line, direction });
            }
        }
    }

    let mut target_classes = Vec::new();
    if let Some(tc_val) = stream_val
        .get(KEY_TARGET_CLASSES)
        .or_else(|| stream_val.get(KEY_CLASSES))
    {
        if let Ok(classes) = serde_yaml::from_value::<Vec<String>>(tc_val.clone()) {
            target_classes = classes;
        } else if let Some(tc_str) = tc_val.as_str()
            && let Ok(classes) = serde_json::from_str::<Vec<String>>(tc_str)
        {
            target_classes = classes;
        }
    }
    if target_classes.is_empty()
        && let Some(gtc) = cfg.get_nested(&[KEY_TRIGGER, KEY_TARGET_CLASSES])
    {
        if let Ok(classes) = serde_yaml::from_value::<Vec<String>>(gtc.clone()) {
            target_classes = classes;
        } else if let Some(tc_str) = gtc.as_str()
            && let Ok(classes) = serde_json::from_str::<Vec<String>>(tc_str)
        {
            target_classes = classes;
        }
    }

    let mut rules = Vec::new();
    if let Some(r_val) = stream_val.get(KEY_RULES) {
        if let Ok(parsed_rules) = serde_yaml::from_value::<Vec<DetectionRule>>(r_val.clone()) {
            rules = parsed_rules;
        } else if let Some(r_str) = r_val.as_str()
            && let Ok(parsed_rules) = serde_json::from_str::<Vec<DetectionRule>>(r_str)
        {
            rules = parsed_rules;
        }
    }
    if rules.is_empty()
        && let Some(gr) = cfg.get_nested(&[KEY_TRIGGER, KEY_RULES])
    {
        if let Ok(parsed_rules) = serde_yaml::from_value::<Vec<DetectionRule>>(gr.clone()) {
            rules = parsed_rules;
        } else if let Some(r_str) = gr.as_str()
            && let Ok(parsed_rules) = serde_json::from_str::<Vec<DetectionRule>>(r_str)
        {
            rules = parsed_rules;
        }
    }

    ZoneConfig {
        enabled,
        roi,
        trigger_line,
        target_classes,
        rules,
    }
}

pub fn apply_to_yaml(stream_id: &str, zone_cfg: &ZoneConfig, cfg: &mut YamlConfig) {
    if !cfg.root().is_mapping() {
        *cfg.root_mut() = Value::Mapping(serde_yaml::Mapping::new());
    }
    let root_map = cfg.root_mut().as_mapping_mut().unwrap();
    let trigger_key = Value::String(KEY_TRIGGER.to_string());
    if !root_map.contains_key(&trigger_key) || !root_map[&trigger_key].is_mapping() {
        root_map.insert(trigger_key.clone(), Value::Mapping(serde_yaml::Mapping::new()));
    }
    let trigger_map = root_map.get_mut(&trigger_key).unwrap().as_mapping_mut().unwrap();
    let stream_key = Value::String(stream_id.to_string());
    let old_model = trigger_map
        .get(&stream_key)
        .and_then(|v| v.as_mapping())
        .and_then(|m| m.get(&Value::String(KEY_MODEL.to_string())))
        .cloned();

    let mut val = super::zone::to_value(zone_cfg);
    if let (Some(m), Some(m_map)) = (old_model, val.as_mapping_mut()) {
        m_map.insert(Value::String(KEY_MODEL.to_string()), m);
    }
    trigger_map.insert(stream_key, val);

    if !zone_cfg.target_classes.is_empty() || !zone_cfg.rules.is_empty() {
        let tc_val = if !zone_cfg.target_classes.is_empty() {
            serde_yaml::to_value(&zone_cfg.target_classes).ok()
        } else {
            None
        };
        let rules_val = if !zone_cfg.rules.is_empty() {
            serde_yaml::to_value(&zone_cfg.rules).ok()
        } else {
            None
        };
        super::trigger::set_detection_value(cfg, tc_val, rules_val);
    }
}

pub fn from_yaml_all(cfg: &YamlConfig) -> HashMap<String, ZoneConfig> {
    let mut map = HashMap::new();
    if let Some(Value::Mapping(t_map)) = cfg.get_value(KEY_TRIGGER) {
        for (k, _) in t_map {
            if let Some(s) = k.as_str()
                && s != KEY_TARGET_CLASSES
                && s != KEY_RULES
                && s != KEY_HTTP_POST
            {
                map.insert(s.to_string(), from_yaml(cfg, s));
            }
        }
    }
    map
}

pub fn load_from_file<P: AsRef<std::path::Path>>(path: P, stream_id: &str) -> ZoneConfig {
    let cfg = YamlConfig::load_or_default(path);
    from_yaml(&cfg, stream_id)
}

pub fn save_to_file<P: AsRef<std::path::Path>>(
    path: P,
    stream_id: &str,
    zone_cfg: &ZoneConfig,
) -> std::io::Result<()> {
    let mut config = YamlConfig::load_or_default(path);
    apply_to_yaml(stream_id, zone_cfg, &mut config);
    config.save()
}

pub fn update_channel_zone(content: &str, stream_id: &str, cfg: &ZoneConfig) -> String {
    let mut config = YamlConfig::new(super::path::DEFAULT_CONFIG_PATH);
    if let Ok(c) = serde_yaml::from_str::<serde_yaml::Value>(content) {
        *config.root_mut() = c;
    }
    apply_to_yaml(stream_id, cfg, &mut config);
    config.format().unwrap_or_default()
}

pub fn update_stream_zone(content: &str, stream_id: &str, cfg: &ZoneConfig) -> String {
    update_channel_zone(content, stream_id, cfg)
}
