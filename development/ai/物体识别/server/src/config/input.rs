use serde_yaml::{Mapping, Value};
use std::collections::HashSet;
use std::io;
use super::r#const::*;
use super::YamlConfig;

pub use super::objects::StreamConfig;

pub fn load_config() -> Vec<StreamConfig> {
    let path = super::get_config_path();
    let cfg = YamlConfig::load_or_default(&path);
    from_yaml(&cfg)
}

pub fn save_config(streams: &[StreamConfig]) -> io::Result<()> {
    let path = super::get_config_path();
    let mut cfg = YamlConfig::load_or_default(&path);
    apply_to_yaml(streams, &mut cfg);
    cfg.save()
}

pub fn from_yaml(cfg: &YamlConfig) -> Vec<StreamConfig> {
    let mut list = Vec::new();
    if let Some(Value::Mapping(map)) = cfg.get_value(KEY_INPUT) {
        let mut keys: Vec<&Value> = map.keys().collect();
        keys.sort_by(|a, b| a.as_str().cmp(&b.as_str()));
        for k in keys {
            if let (Some(id), Some(url)) = (k.as_str(), map.get(k).and_then(|v| v.as_str())) {
                let enabled = cfg
                    .get_nested(&[KEY_TRIGGER, id, KEY_ENABLED])
                    .and_then(|v| v.as_bool())
                    .unwrap_or(true);
                let model = cfg
                    .get_nested(&[KEY_TRIGGER, id, KEY_MODEL])
                    .and_then(|v| v.as_str())
                    .unwrap_or(DEFAULT_MODEL)
                    .to_string();
                list.push(StreamConfig {
                    id: id.to_string(),
                    input: url.to_string(),
                    enabled,
                    model,
                });
            }
        }
    }
    list
}

pub fn from_yaml_pairs(cfg: &YamlConfig) -> Vec<(String, String)> {
    let mut list = Vec::new();
    if let Some(Value::Mapping(map)) = cfg.get_value(KEY_INPUT) {
        let mut keys: Vec<&Value> = map.keys().collect();
        keys.sort_by(|a, b| a.as_str().cmp(&b.as_str()));
        for k in keys {
            if let (Some(id), Some(url)) = (k.as_str(), map.get(k).and_then(|v| v.as_str())) {
                list.push((id.to_string(), url.to_string()));
            }
        }
    }
    list
}

pub fn apply_to_yaml_pairs(streams: &[(String, String)], cfg: &mut YamlConfig) {
    if streams.is_empty() {
        cfg.remove(KEY_INPUT);
    } else {
        let mut map = Mapping::new();
        for (id, url) in streams {
            map.insert(Value::String(id.clone()), Value::String(url.clone()));
        }
        cfg.set_value(KEY_INPUT, Value::Mapping(map));
    }
}

pub fn apply_to_yaml(streams: &[StreamConfig], cfg: &mut YamlConfig) {
    if streams.is_empty() {
        cfg.remove(KEY_INPUT);
        cfg.remove(KEY_TRIGGER);
        return;
    }

    let mut input_map = Mapping::new();
    for s in streams {
        input_map.insert(Value::String(s.id.clone()), Value::String(s.input.clone()));
    }
    cfg.set_value(KEY_INPUT, Value::Mapping(input_map));

    let valid_ids: HashSet<&str> = streams.iter().map(|s| s.id.as_str()).collect();

    if !cfg.root().is_mapping() {
        *cfg.root_mut() = Value::Mapping(Mapping::new());
    }
    let root_map = cfg.root_mut().as_mapping_mut().unwrap();
    let trigger_key = Value::String(KEY_TRIGGER.to_string());
    if !root_map.contains_key(&trigger_key) || !root_map[&trigger_key].is_mapping() {
        root_map.insert(trigger_key.clone(), Value::Mapping(Mapping::new()));
    }
    let trigger_map = root_map.get_mut(&trigger_key).unwrap().as_mapping_mut().unwrap();

    let to_remove: Vec<Value> = trigger_map
        .keys()
        .filter_map(|k| {
            if let Some(s) = k.as_str()
                && s != KEY_TARGET_CLASSES
                && s != KEY_RULES
                && s != KEY_HTTP_POST
                && !valid_ids.contains(s)
            {
                return Some(k.clone());
            }
            None
        })
        .collect();
    for k in to_remove {
        trigger_map.remove(&k);
    }

    for s in streams {
        let k = Value::String(s.id.clone());
        if let Some(stream_val) = trigger_map.get_mut(&k) {
            if let Some(s_map) = stream_val.as_mapping_mut() {
                s_map.insert(Value::String(KEY_ENABLED.to_string()), Value::Bool(s.enabled));
                s_map.insert(Value::String(KEY_MODEL.to_string()), Value::String(s.model.clone()));
            }
        } else {
            let mut s_map = Mapping::new();
            s_map.insert(Value::String(KEY_ENABLED.to_string()), Value::Bool(s.enabled));
            s_map.insert(Value::String(KEY_MODEL.to_string()), Value::String(s.model.clone()));
            s_map.insert(
                Value::String(KEY_ROI.to_string()),
                serde_yaml::to_value([0.050, 0.050, 0.950, 0.950]).unwrap(),
            );
            trigger_map.insert(k, Value::Mapping(s_map));
        }
    }
}

pub fn save_to_file<P: AsRef<std::path::Path>>(
    path: P,
    streams: &[StreamConfig],
) -> io::Result<()> {
    let mut cfg = YamlConfig::load_or_default(path);
    apply_to_yaml(streams, &mut cfg);
    cfg.save()
}

pub fn update_input_streams(content: &str, streams: &[(String, String)]) -> String {
    let list: Vec<(String, String, bool)> = streams
        .iter()
        .map(|(id, url)| (id.clone(), url.clone(), true))
        .collect();
    update_input_streams_full(content, &list)
}

pub fn update_input_streams_full(
    content: &str,
    streams: &[(String, String, bool)],
) -> String {
    let configs: Vec<StreamConfig> = streams
        .iter()
        .map(|(id, url, en)| StreamConfig {
            id: id.clone(),
            input: url.clone(),
            enabled: *en,
            model: DEFAULT_MODEL.to_string(),
        })
        .collect();
    update_input_streams_configs(content, &configs)
}

pub fn update_input_streams_configs(
    content: &str,
    streams: &[StreamConfig],
) -> String {
    let mut config = YamlConfig::new(super::path::DEFAULT_CONFIG_PATH);
    if let Ok(c) = serde_yaml::from_str::<serde_yaml::Value>(content) {
        *config.root_mut() = c;
    }
    apply_to_yaml(streams, &mut config);
    config.format().unwrap_or_default()
}
