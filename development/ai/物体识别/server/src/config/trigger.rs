use crate::object_tracker::rules::DetectionRule;
use serde_yaml::Value;
use std::io;
use super::r#const::*;
use super::YamlConfig;

pub use super::objects::TriggerConfig;

pub fn load_config() -> TriggerConfig {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml(&cfg)
}

pub fn save_config(
    target_classes: &[String],
    rules: &[DetectionRule],
) -> io::Result<()> {
    let path = super::get_config_path();
    let mut cfg = YamlConfig::load_or_default(&path);
    apply_to_yaml(target_classes, rules, &mut cfg);
    cfg.save()
}

pub fn from_yaml(cfg: &YamlConfig) -> TriggerConfig {
    let mut target_classes = Vec::new();
    let mut rules = Vec::new();
    if let Some(trigger_val) = cfg.get_value(KEY_TRIGGER) {
        if let Some(gtc) = trigger_val.get(KEY_TARGET_CLASSES) {
            if let Ok(classes) = serde_yaml::from_value::<Vec<String>>(gtc.clone()) {
                target_classes = classes;
            } else if let Some(tc_str) = gtc.as_str()
                && let Ok(classes) = serde_json::from_str::<Vec<String>>(tc_str)
            {
                target_classes = classes;
            }
        }
        if let Some(gr) = trigger_val.get(KEY_RULES) {
            if let Ok(parsed_rules) = serde_yaml::from_value::<Vec<DetectionRule>>(gr.clone()) {
                rules = parsed_rules;
            } else if let Some(r_str) = gr.as_str()
                && let Ok(parsed_rules) = serde_json::from_str::<Vec<DetectionRule>>(r_str)
            {
                rules = parsed_rules;
            }
        }
    }
    TriggerConfig {
        target_classes,
        rules,
    }
}

pub fn apply_to_yaml(
    target_classes: &[String],
    rules: &[DetectionRule],
    cfg: &mut YamlConfig,
) {
    let tc_val = if !target_classes.is_empty() {
        serde_yaml::to_value(target_classes).ok()
    } else {
        None
    };
    let rules_val = if !rules.is_empty() {
        serde_yaml::to_value(rules).ok()
    } else {
        None
    };
    set_detection_value(cfg, tc_val, rules_val);
}

pub fn set_detection_value(
    cfg: &mut YamlConfig,
    target_classes: Option<Value>,
    rules: Option<Value>,
) {
    if !cfg.root().is_mapping() {
        *cfg.root_mut() = Value::Mapping(serde_yaml::Mapping::new());
    }
    let root_map = cfg.root_mut().as_mapping_mut().unwrap();
    let trigger_key = Value::String(KEY_TRIGGER.to_string());
    if !root_map.contains_key(&trigger_key) || !root_map[&trigger_key].is_mapping() {
        root_map.insert(trigger_key.clone(), Value::Mapping(serde_yaml::Mapping::new()));
    }
    let trigger_map = root_map.get_mut(&trigger_key).unwrap().as_mapping_mut().unwrap();

    let tc_key = Value::String(KEY_TARGET_CLASSES.to_string());
    match target_classes {
        Some(v) => {
            trigger_map.insert(tc_key, v);
        }
        None => {
            trigger_map.remove(&tc_key);
        }
    }

    let rules_key = Value::String(KEY_RULES.to_string());
    match rules {
        Some(v) => {
            trigger_map.insert(rules_key, v);
        }
        None => {
            trigger_map.remove(&rules_key);
        }
    }
}

pub fn update_global_detection(
    content: &str,
    target_classes: &[String],
    rules: &[DetectionRule],
) -> String {
    let mut config = YamlConfig::new(super::path::DEFAULT_CONFIG_PATH);
    if let Ok(c) = serde_yaml::from_str::<serde_yaml::Value>(content) {
        *config.root_mut() = c;
    }
    apply_to_yaml(target_classes, rules, &mut config);
    config.format().unwrap_or_default()
}

pub fn load_from_file<P: AsRef<std::path::Path>>(
    path: P,
) -> TriggerConfig {
    let cfg = YamlConfig::load_or_default(path);
    from_yaml(&cfg)
}

pub fn save_to_file<P: AsRef<std::path::Path>>(
    path: P,
    target_classes: &[String],
    rules: &[DetectionRule],
) -> io::Result<()> {
    let mut cfg = YamlConfig::load_or_default(path);
    apply_to_yaml(target_classes, rules, &mut cfg);
    cfg.save()
}
