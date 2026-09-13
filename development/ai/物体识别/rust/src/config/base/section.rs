use std::collections::HashMap;

#[derive(Debug, Clone, Default)]
pub struct ConfigSection {
    pub(crate) values: HashMap<String, String>,
    pub(crate) children: HashMap<String, ConfigSection>,
    pub(crate) items: Vec<String>,
}

impl ConfigSection {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert_value(&mut self, key: String, value: String) {
        self.values.insert(key, value);
    }

    pub fn get_str(&self, key: &str) -> Option<&str> {
        match self.values.get(key) {
            Some(v) => Some(v.as_str()),
            None => None,
        }
    }

    pub fn get_string(&self, key: &str) -> Option<String> {
        match self.values.get(key) {
            Some(v) => Some(v.clone()),
            None => None,
        }
    }

    pub fn get_u16(&self, key: &str) -> Option<u16> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<u16>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn get_u64(&self, key: &str) -> Option<u64> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<u64>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn get_f64(&self, key: &str) -> Option<f64> {
        let val_str = match self.values.get(key) {
            Some(v) => v,
            None => return None,
        };
        match val_str.parse::<f64>() {
            Ok(n) => Some(n),
            Err(_) => None,
        }
    }

    pub fn remove_value(&mut self, key: &str) -> Option<String> {
        self.values.remove(key)
    }

    pub fn contains_value(&self, key: &str) -> bool {
        self.values.contains_key(key)
    }

    pub fn values(&self) -> &HashMap<String, String> {
        &self.values
    }

    pub fn insert_child(&mut self, name: String, child: ConfigSection) {
        self.children.insert(name, child);
    }

    pub fn get_child(&self, name: &str) -> Option<&ConfigSection> {
        self.children.get(name)
    }

    pub fn get_child_mut(&mut self, name: &str) -> Option<&mut ConfigSection> {
        self.children.get_mut(name)
    }

    pub fn remove_child(&mut self, name: &str) -> Option<ConfigSection> {
        self.children.remove(name)
    }

    pub fn contains_child(&self, name: &str) -> bool {
        self.children.contains_key(name)
    }

    pub fn children(&self) -> &HashMap<String, ConfigSection> {
        &self.children
    }

    pub fn add_item(&mut self, item: String) {
        self.items.push(item);
    }

    pub fn items(&self) -> &[String] {
        &self.items
    }

    pub fn clear(&mut self) {
        self.values.clear();
        self.children.clear();
        self.items.clear();
    }
}
