use crate::config::app::r#const::*;
use serde_yaml::{Mapping, Value};
use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};

pub static CONFIG_FILE_MUTEX: Mutex<()> = Mutex::new(());
static GLOBAL_CONFIG_PATH: OnceLock<String> = OnceLock::new();

pub fn set_global_config_path(path: impl Into<String>) {
    let p = path.into();
    let _ = GLOBAL_CONFIG_PATH.set(p);
}

pub fn get_global_config_path() -> String {
    GLOBAL_CONFIG_PATH
        .get()
        .cloned()
        .unwrap_or_else(|| crate::prepare::resolve_config_path().unwrap_or_else(|_| "config.yaml".to_string()))
}

#[derive(Debug, Clone)]
pub struct YamlConfig {
    path: PathBuf,
    root: Value,
}

impl YamlConfig {
    pub fn new<P: AsRef<Path>>(path: P) -> Self {
        Self {
            path: path.as_ref().to_path_buf(),
            root: Value::Mapping(Mapping::new()),
        }
    }

    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let p = path.as_ref().to_path_buf();
        let content = std::fs::read_to_string(&p)?;
        let root: Value = if content.trim().is_empty() {
            Value::Mapping(Mapping::new())
        } else {
            serde_yaml::from_str(&content)?
        };
        Ok(Self { path: p, root })
    }

    pub fn load_or_default<P: AsRef<Path>>(path: P) -> Self {
        let p = path.as_ref().to_path_buf();
        Self::load_from_file(&p).unwrap_or_else(|_| Self::new(p))
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn set_path<P: AsRef<Path>>(&mut self, path: P) {
        self.path = path.as_ref().to_path_buf();
    }

    pub fn root(&self) -> &Value {
        &self.root
    }

    pub fn root_mut(&mut self) -> &mut Value {
        &mut self.root
    }

    pub fn get_value(&self, key: &str) -> Option<&Value> {
        self.root.get(Value::String(key.to_string()))
    }

    pub fn get_nested(&self, path: &[&str]) -> Option<&Value> {
        let mut curr = &self.root;
        for key in path {
            match curr {
                Value::Mapping(map) => {
                    curr = map.get(Value::String(key.to_string()))?;
                }
                _ => return None,
            }
        }
        Some(curr)
    }

    pub fn get_str(&self, key: &str) -> Option<&str> {
        self.get_value(key).and_then(|v| v.as_str())
    }

    pub fn get_u64(&self, key: &str) -> Option<u64> {
        self.get_value(key).and_then(|v| v.as_u64())
    }

    pub fn get_bool(&self, key: &str) -> Option<bool> {
        self.get_value(key).and_then(|v| v.as_bool())
    }

    pub fn set_value(&mut self, key: impl Into<String>, val: Value) {
        if !self.root.is_mapping() {
            self.root = Value::Mapping(Mapping::new());
        }
        if let Value::Mapping(map) = &mut self.root {
            map.insert(Value::String(key.into()), val);
        }
    }

    pub fn set_nested(&mut self, path: &[&str], val: Value) {
        if path.is_empty() {
            self.root = val;
            return;
        }
        if !self.root.is_mapping() {
            self.root = Value::Mapping(Mapping::new());
        }

        let mut curr = &mut self.root;
        for &key in &path[..path.len() - 1] {
            if !curr.is_mapping() {
                *curr = Value::Mapping(Mapping::new());
            }
            let map = curr.as_mapping_mut().unwrap();
            let k = Value::String(key.to_string());
            if !map.contains_key(&k) || !map[&k].is_mapping() {
                map.insert(k.clone(), Value::Mapping(Mapping::new()));
            }
            curr = map.get_mut(&k).unwrap();
        }

        if let Value::Mapping(map) = curr {
            map.insert(Value::String(path.last().unwrap().to_string()), val);
        }
    }

    pub fn set_string(&mut self, key: impl Into<String>, val: impl Into<String>) {
        self.set_value(key, Value::String(val.into()));
    }

    pub fn set_u64(&mut self, key: impl Into<String>, val: u64) {
        self.set_value(key, Value::Number(val.into()));
    }

    pub fn set_bool(&mut self, key: impl Into<String>, val: bool) {
        self.set_value(key, Value::Bool(val));
    }

    pub fn remove(&mut self, key: &str) -> Option<Value> {
        if let Value::Mapping(map) = &mut self.root {
            map.remove(Value::String(key.to_string()))
        } else {
            None
        }
    }

    pub fn remove_nested(&mut self, path: &[&str]) -> Option<Value> {
        if path.is_empty() {
            return None;
        }
        if path.len() == 1 {
            return self.remove(path[0]);
        }

        let mut curr = &mut self.root;
        for &key in &path[..path.len() - 1] {
            match curr {
                Value::Mapping(map) => {
                    curr = map.get_mut(Value::String(key.to_string()))?;
                }
                _ => return None,
            }
        }

        if let Value::Mapping(map) = curr {
            map.remove(Value::String(path.last().unwrap().to_string()))
        } else {
            None
        }
    }

    pub fn get_alert_url(&self) -> Option<String> {
        self.get_nested(&[KEY_ALERT, KEY_URL])
            .or_else(|| self.get_nested(&["alert", "url"]))
            .and_then(|v| v.as_str())
            .map(|s| s.to_string())
            .or_else(|| self.get_str(KEY_ALERT_URL).map(|s| s.to_string()))
            .or_else(|| self.get_str(KEY_ALERT_CALLBACK_URL).map(|s| s.to_string()))
            .filter(|s| !s.trim().is_empty())
    }

    pub fn set_alert_url(&mut self, url: Option<&str>) {
        let (_, cd, to) = self.get_alert();
        self.set_alert(url, cd, to);
    }

    pub fn get_alert_cooldown_sec(&self) -> Option<u64> {
        self.get_nested(&[KEY_ALERT, KEY_COOLDOWN_SEC])
            .or_else(|| self.get_nested(&["alert", "cooldown_sec"]))
            .and_then(|v| v.as_u64())
            .or_else(|| self.get_u64(KEY_ALERT_COOLDOWN_SEC))
    }

    pub fn set_alert_cooldown_sec(&mut self, sec: Option<u64>) {
        let (url, _, to) = self.get_alert();
        self.set_alert(url.as_deref(), sec, to);
    }

    pub fn get_alert_timeout_sec(&self) -> Option<u64> {
        self.get_nested(&[KEY_ALERT, KEY_TIMEOUT_SEC])
            .or_else(|| self.get_nested(&["alert", "timeout_sec"]))
            .and_then(|v| v.as_u64())
            .or_else(|| self.get_u64(KEY_ALERT_TIMEOUT_SEC))
    }

    pub fn set_alert_timeout_sec(&mut self, sec: Option<u64>) {
        let (url, cd, _) = self.get_alert();
        self.set_alert(url.as_deref(), cd, sec);
    }

    pub fn get_alert(&self) -> (Option<String>, Option<u64>, Option<u64>) {
        (
            self.get_alert_url(),
            self.get_alert_cooldown_sec(),
            self.get_alert_timeout_sec(),
        )
    }

    pub fn set_alert(
        &mut self,
        alert_url: Option<&str>,
        cooldown_sec: Option<u64>,
        timeout_sec: Option<u64>,
    ) {
        self.remove(KEY_ALERT_URL);
        self.remove(KEY_ALERT_CALLBACK_URL);
        self.remove(KEY_ALERT_COOLDOWN_SEC);
        self.remove(KEY_ALERT_TIMEOUT_SEC);

        let curr_url = alert_url.map(|s| s.trim().to_string()).or_else(|| self.get_alert_url());
        let curr_cd = cooldown_sec.or_else(|| self.get_alert_cooldown_sec());
        let curr_to = timeout_sec.or_else(|| self.get_alert_timeout_sec());

        let url_clean = curr_url.as_deref().filter(|s| !s.trim().is_empty());
        if url_clean.is_none() && curr_cd.is_none() && curr_to.is_none() {
            self.remove(KEY_ALERT);
            return;
        }

        let mut alert_map = Mapping::new();
        if let Some(u) = url_clean {
            alert_map.insert(Value::String(KEY_URL.to_string()), Value::String(u.to_string()));
        }
        if let Some(cd) = curr_cd {
            alert_map.insert(Value::String(KEY_COOLDOWN_SEC.to_string()), Value::Number((cd as u64).into()));
        }
        if let Some(to) = curr_to {
            alert_map.insert(Value::String(KEY_TIMEOUT_SEC.to_string()), Value::Number((to as u64).into()));
        }
        self.set_value(KEY_ALERT, Value::Mapping(alert_map));
    }

    pub fn get_input_streams(&self) -> Vec<(String, String)> {
        let mut list = Vec::new();
        if let Some(Value::Mapping(map)) = self.get_value(KEY_INPUT) {
            for (k, v) in map {
                if let (Some(id), Some(url)) = (k.as_str(), v.as_str()) {
                    list.push((id.to_string(), url.to_string()));
                }
            }
        }
        list
    }

    pub fn set_input_streams(&mut self, streams: &[(String, String)]) {
        if streams.is_empty() {
            self.remove(KEY_INPUT);
        } else {
            let mut map = Mapping::new();
            for (id, url) in streams {
                map.insert(Value::String(id.clone()), Value::String(url.clone()));
            }
            self.set_value(KEY_INPUT, Value::Mapping(map));
        }
    }

    pub fn get_server_host(&self) -> Option<String> {
        self.get_nested(&[KEY_SERVER, KEY_HOST]).and_then(|v| v.as_str()).map(|s| s.to_string())
    }

    pub fn set_server_host(&mut self, host: impl Into<String>) {
        self.set_nested(&[KEY_SERVER, KEY_HOST], Value::String(host.into()));
    }

    pub fn get_server_port(&self) -> Option<u16> {
        self.get_nested(&[KEY_SERVER, KEY_PORT]).and_then(|v| v.as_u64()).map(|n| n as u16)
    }

    pub fn set_server_port(&mut self, port: u16) {
        self.set_nested(&[KEY_SERVER, KEY_PORT], Value::Number((port as u64).into()));
    }

    pub fn get_stream_zone_value(&self, stream_id: &str) -> Option<&Value> {
        self.get_nested(&[KEY_TRIGGER, stream_id])
    }

    pub fn set_stream_zone_value(&mut self, stream_id: &str, zone_val: Value) {
        self.set_nested(&[KEY_TRIGGER, stream_id], zone_val);
    }

    pub fn remove_stream_zone(&mut self, stream_id: &str) -> Option<Value> {
        self.remove_nested(&[KEY_TRIGGER, stream_id])
    }

    pub fn to_formatted_yaml(&self) -> Result<String, serde_yaml::Error> {
        let mut root_clone = self.root.clone();
        if let Value::Mapping(ref mut map) = root_clone {
            let input_empty = match map.get(&Value::String(KEY_INPUT.to_string())) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if input_empty {
                map.remove(&Value::String(KEY_INPUT.to_string()));
            }

            let trigger_empty = match map.get(&Value::String(KEY_TRIGGER.to_string())) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if trigger_empty {
                map.remove(&Value::String(KEY_TRIGGER.to_string()));
            }

            let alert_empty = match map.get(&Value::String(KEY_ALERT.to_string())) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if alert_empty {
                map.remove(&Value::String(KEY_ALERT.to_string()));
            }
        }
        let raw = serde_yaml::to_string(&root_clone)?;
        Ok(prettify_yaml_sections(&raw))
    }

    pub fn save(&self) -> Result<(), std::io::Error> {
        let _guard = CONFIG_FILE_MUTEX.lock().unwrap();
        let formatted = self
            .to_formatted_yaml()
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;

        if let Some(parent) = self.path.parent()
            && !parent.as_os_str().is_empty()
            && !parent.exists()
        {
            std::fs::create_dir_all(parent)?;
        }

        std::fs::write(&self.path, formatted)
    }
}

pub fn prettify_yaml_sections(yaml: &str) -> String {
    let lines: Vec<&str> = yaml.lines().collect();
    let mut out = String::new();

    let mut prev_was_indented = false;

    for (i, &line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        if trimmed == "input: null" || trimmed == "trigger: null" || trimmed == "alert: null" {
            continue;
        }
        if trimmed == "input:" || trimmed == "trigger:" || trimmed == "alert:" {
            let next_is_indented = lines
                .get(i + 1)
                .map(|l| l.starts_with("  ") || l.starts_with('\t'))
                .unwrap_or(false);
            if !next_is_indented {
                continue;
            }
        }

        let is_top_level = !line.starts_with(' ')
            && !line.starts_with('\t')
            && !line.starts_with('-')
            && line.contains(':');

        if i > 0 && is_top_level {
            let next_is_indented = lines.get(i + 1).map(|l| l.starts_with("  ")).unwrap_or(false);
            if (prev_was_indented || next_is_indented) && !out.ends_with("\n\n") {
                out.push('\n');
            }
        }

        out.push_str(line);
        out.push('\n');

        prev_was_indented = line.starts_with("  ") || line.starts_with('\t');
    }

    out
}
