use super::r#const::*;
use serde_yaml::{Mapping, Value};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

pub static CONFIG_FILE_MUTEX: Mutex<()> = Mutex::new(());

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

    pub fn format(&self) -> Result<String, serde_yaml::Error> {
        let mut root_clone = self.root.clone();
        if let Value::Mapping(ref mut map) = root_clone {
            let input_k = Value::String(KEY_INPUT.to_string());
            let input_empty = match map.get(&input_k) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if input_empty {
                map.remove(&input_k);
            }

            let trigger_k = Value::String(KEY_TRIGGER.to_string());
            let trigger_empty = match map.get(&trigger_k) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if trigger_empty {
                map.remove(&trigger_k);
            } else if let Some(trigger_val) = map.get_mut(&trigger_k)
                && let Some(t_map) = trigger_val.as_mapping_mut()
            {
                let mut ordered = Mapping::new();
                let tc_k = Value::String(KEY_TARGET_CLASSES.to_string());
                let rules_k = Value::String(KEY_RULES.to_string());

                if let Some(v) = t_map.get(&tc_k) {
                    ordered.insert(tc_k.clone(), v.clone());
                }
                if let Some(v) = t_map.get(&rules_k) {
                    ordered.insert(rules_k.clone(), v.clone());
                }
                for (k, v) in t_map.iter() {
                    if k != &tc_k && k != &rules_k {
                        ordered.insert(k.clone(), v.clone());
                    }
                }
                *t_map = ordered;
            }

            let alert_k = Value::String(KEY_ALERT.to_string());
            let alert_empty = match map.get(&alert_k) {
                Some(Value::Null) => true,
                Some(Value::Mapping(m)) => m.is_empty(),
                _ => false,
            };
            if alert_empty {
                map.remove(&alert_k);
            }
        }
        let raw = serde_yaml::to_string(&root_clone)?;
        Ok(super::pretty::prettify_yaml(&raw))
    }

    pub fn save(&self) -> Result<(), std::io::Error> {
        let _guard = CONFIG_FILE_MUTEX.lock().unwrap();
        let formatted = self
            .format()
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
