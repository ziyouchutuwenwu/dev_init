use std::collections::HashMap;
use std::path::Path;
use super::section::ConfigSection;

#[derive(Debug, Clone, Default)]
pub struct ConfigParser {
    pub(crate) sections: HashMap<String, ConfigSection>,
}

impl ConfigParser {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(&path)?;
        Self::from_str(&content)
    }

    pub fn from_str(content: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let mut sections: HashMap<String, ConfigSection> = HashMap::new();
        let mut current_sec_name = String::new();
        let mut current_child_name = String::new();
        let mut current_grand_name = String::new();

        for line_raw in content.lines() {
            let line_no_comment = match line_raw.find('#') {
                Some(idx) => &line_raw[..idx],
                None => line_raw,
            };
            let line_trimmed = line_no_comment.trim();
            if line_trimmed.is_empty() {
                continue;
            }

            let mut indent = 0;
            for c in line_no_comment.chars() {
                if c.is_whitespace() {
                    indent += 1;
                } else {
                    break;
                }
            }

            if indent == 0 && line_trimmed.ends_with(':') {
                current_sec_name = line_trimmed.trim_end_matches(':').trim().to_lowercase();
                current_child_name.clear();
                current_grand_name.clear();
                if !sections.contains_key(&current_sec_name) {
                    sections.insert(current_sec_name.clone(), ConfigSection::new());
                }
                continue;
            }

            if current_sec_name.is_empty() {
                continue;
            }

            let sec = match sections.get_mut(&current_sec_name) {
                Some(s) => s,
                None => continue,
            };

            if line_trimmed.starts_with("- ") {
                let val = match line_trimmed.strip_prefix("- ") {
                    Some(v) => v.trim().trim_matches('"').trim_matches('\'').trim().to_string(),
                    None => String::new(),
                };
                if !val.is_empty() {
                    sec.add_item(val);
                }
                continue;
            }

            if line_trimmed.ends_with(':') {
                let name = line_trimmed.trim_end_matches(':').trim().to_lowercase();
                if current_child_name.is_empty() || indent <= 2 {
                    current_child_name = name;
                    current_grand_name.clear();
                    if !sec.contains_child(&current_child_name) {
                        sec.insert_child(current_child_name.clone(), ConfigSection::new());
                    }
                } else {
                    current_grand_name = name;
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        if !child_sec.contains_child(&current_grand_name) {
                            child_sec.insert_child(current_grand_name.clone(), ConfigSection::new());
                        }
                    }
                }
                continue;
            }

            if let Some((k, v)) = line_trimmed.split_once(':') {
                let k = k.trim().trim_matches('"').trim_matches('\'').trim().to_lowercase();
                let v = v.trim().trim_matches('"').trim_matches('\'').trim().to_string();
                if k.is_empty() || v.is_empty() {
                    continue;
                }

                if !current_grand_name.is_empty() {
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        if let Some(grand_sec) = child_sec.get_child_mut(&current_grand_name) {
                            grand_sec.insert_value(k, v);
                            continue;
                        }
                    }
                }

                if !current_child_name.is_empty() {
                    if let Some(child_sec) = sec.get_child_mut(&current_child_name) {
                        child_sec.insert_value(k, v);
                        continue;
                    }
                }

                sec.insert_value(k, v);
            }
        }

        Ok(Self { sections })
    }

    pub fn insert_section(&mut self, name: String, section: ConfigSection) {
        self.sections.insert(name, section);
    }

    pub fn get_section(&self, name: &str) -> Option<&ConfigSection> {
        self.sections.get(name)
    }

    pub fn get_section_mut(&mut self, name: &str) -> Option<&mut ConfigSection> {
        self.sections.get_mut(name)
    }

    pub fn remove_section(&mut self, name: &str) -> Option<ConfigSection> {
        self.sections.remove(name)
    }

    pub fn contains_section(&self, name: &str) -> bool {
        self.sections.contains_key(name)
    }

    pub fn sections(&self) -> &HashMap<String, ConfigSection> {
        &self.sections
    }
}
