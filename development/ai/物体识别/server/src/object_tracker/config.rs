use super::zone::{CrossingDirection, RoiConfig, ZoneLineConfig};
use crate::config::YamlConfig;
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ZoneConfig {
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(default)]
    pub trigger_box: Option<[f64; 4]>,
    #[serde(default)]
    pub roi: Option<RoiConfig>,
    #[serde(default, alias = "trigger_area")]
    pub trigger_line: Option<ZoneLineConfig>,
    #[serde(default)]
    pub target_classes: Vec<String>,
}

pub type StreamZoneConfig = ZoneConfig;

fn default_true() -> bool {
    true
}

impl Default for ZoneConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            trigger_box: Some([0.10, 0.20, 0.90, 0.80]),
            roi: Some(RoiConfig::Rect([0.10, 0.20, 0.90, 0.80])),
            trigger_line: None,
            target_classes: Vec::new(),
        }
    }
}

impl ZoneConfig {
    pub fn get_trigger_box(&self) -> Option<[f64; 4]> {
        if let Some(tb) = self.trigger_box {
            return Some(tb);
        }
        if let Some(RoiConfig::Rect(r)) = self.roi {
            return Some(r);
        }
        None
    }

    pub fn load_from_yaml_file<P: AsRef<Path>>(path: P, stream_id: &str) -> Self {
        let cfg = match YamlConfig::load_from_file(path) {
            Ok(c) => c,
            Err(_) => return Self::default(),
        };

        let stream_val = match cfg.get_nested(&[crate::config::KEY_TRIGGER, stream_id]) {
            Some(v) => v,
            None => return Self::default(),
        };

        let enabled = stream_val
            .get(crate::config::KEY_ENABLED)
            .and_then(|v| v.as_bool())
            .unwrap_or(true);

        let mut roi = None;
        if let Some(roi_val) = stream_val.get(crate::config::KEY_ROI) {
            if let Ok(rect) = serde_yaml::from_value::<[f64; 4]>(roi_val.clone()) {
                roi = Some(RoiConfig::Rect(rect));
            } else if let Ok(poly) = serde_yaml::from_value::<Vec<[f64; 2]>>(roi_val.clone()) {
                roi = Some(RoiConfig::Polygon(poly));
            } else if let Some(roi_str) = roi_val.as_str() {
                if let Ok(rect) = serde_json::from_str::<[f64; 4]>(roi_str) {
                    roi = Some(RoiConfig::Rect(rect));
                } else if let Ok(poly) = serde_json::from_str::<Vec<[f64; 2]>>(roi_str) {
                    roi = Some(RoiConfig::Polygon(poly));
                }
            }
        }

        let mut trigger_line = None;
        let line_opt = stream_val
            .get(crate::config::KEY_TRIGGER_LINE)
            .or_else(|| stream_val.get(crate::config::KEY_TRIGGER_AREA));
        if let Some(line_val) = line_opt {
            let parsed_line = serde_yaml::from_value::<[[f64; 2]; 2]>(line_val.clone())
                .ok()
                .or_else(|| {
                    line_val
                        .as_str()
                        .and_then(|s| serde_json::from_str::<[[f64; 2]; 2]>(s).ok())
                });
            if let Some(line) = parsed_line {
                let dir_str = stream_val
                    .get(crate::config::KEY_DIRECTION)
                    .and_then(|v| v.as_str())
                    .unwrap_or_default();
                let direction = match dir_str.to_lowercase().as_str() {
                    "forward" => CrossingDirection::Forward,
                    "backward" => CrossingDirection::Backward,
                    _ => CrossingDirection::Any,
                };
                trigger_line = Some(ZoneLineConfig { line, direction });
            }
        }

        let mut trigger_box = None;
        if let Some(tb_val) = stream_val.get(crate::config::KEY_TRIGGER_BOX) {
            if let Ok(rect) = serde_yaml::from_value::<[f64; 4]>(tb_val.clone()) {
                trigger_box = Some(rect);
            } else if let Some(tb_str) = tb_val.as_str() {
                if let Ok(rect) = serde_json::from_str::<[f64; 4]>(tb_str) {
                    trigger_box = Some(rect);
                }
            }
        }
        if trigger_box.is_none() {
            if let Some(RoiConfig::Rect(r)) = roi {
                trigger_box = Some(r);
            }
        }

        Self {
            enabled,
            trigger_box,
            roi,
            trigger_line,
            target_classes: Vec::new(),
        }
    }

    pub fn save_to_yaml_file<P: AsRef<Path>>(
        path: P,
        stream_id: &str,
        cfg: &Self,
    ) -> std::io::Result<()> {
        let file_path = path.as_ref();
        let content = std::fs::read_to_string(file_path).unwrap_or_default();
        let updated = update_yaml_stream_zone(&content, stream_id, cfg);
        std::fs::write(file_path, &updated)?;
        Ok(())
    }
}

fn update_yaml_stream_zone(content: &str, stream_id: &str, cfg: &ZoneConfig) -> String {
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();

    let trigger_idx = lines.iter().position(|l| {
        let t = l.trim();
        t == "trigger:" || t.starts_with("trigger:")
    });

    let tb_rect = cfg.get_trigger_box();
    let tb_str = match &tb_rect {
        Some(r) => format!("[{:.3}, {:.3}, {:.3}, {:.3}]", r[0], r[1], r[2], r[3]),
        None => "null".to_string(),
    };

    let roi_str = match &cfg.roi {
        Some(RoiConfig::Rect(r)) => format!("[{:.3}, {:.3}, {:.3}, {:.3}]", r[0], r[1], r[2], r[3]),
        Some(RoiConfig::Polygon(p)) => {
            serde_json::to_string(p).unwrap_or_else(|_| "[]".to_string())
        }
        None => "null".to_string(),
    };

    let (line_str, dir_str) = match &cfg.trigger_line {
        Some(t) => {
            let s = format!(
                "[[{:.3}, {:.3}], [{:.3}, {:.3}]]",
                t.line[0][0], t.line[0][1], t.line[1][0], t.line[1][1]
            );
            let d = match t.direction {
                CrossingDirection::Forward => "forward",
                CrossingDirection::Backward => "backward",
                CrossingDirection::Any => "any",
            };
            (s, d)
        }
        None => ("null".to_string(), "any"),
    };

    let block_lines = vec![
        format!("  {}:", stream_id),
        format!("    enabled: {}", cfg.enabled),
        format!("    trigger_box: {}", tb_str),
        format!("    roi: {}", roi_str),
        format!("    trigger_line: {}", line_str),
        format!("    direction: {}", dir_str),
    ];

    if let Some(t_idx) = trigger_idx {
        let mut stream_start = None;
        let mut stream_end = None;

        let mut i = t_idx + 1;
        while i < lines.len() {
            let line = &lines[i];
            let trimmed = line.trim();
            if !line.is_empty() && !line.starts_with(' ') && !line.starts_with('\t') {
                break;
            }

            if trimmed == format!("{}:", stream_id)
                || trimmed.starts_with(&format!("{}:", stream_id))
            {
                stream_start = Some(i);
                let mut j = i + 1;
                while j < lines.len() {
                    let next_line = &lines[j];
                    if !next_line.is_empty()
                        && (next_line.starts_with("  ") && !next_line.starts_with("    ")
                            || (!next_line.starts_with(' ') && !next_line.starts_with('\t')))
                    {
                        break;
                    }
                    j += 1;
                }
                stream_end = Some(j);
                break;
            }
            i += 1;
        }

        if let (Some(start), Some(end)) = (stream_start, stream_end) {
            lines.splice(start..end, block_lines);
        } else {
            let mut insert_pos = t_idx + 1;
            while insert_pos < lines.len() {
                let l = &lines[insert_pos];
                if !l.is_empty() && !l.starts_with(' ') && !l.starts_with('\t') {
                    break;
                }
                insert_pos += 1;
            }
            lines.splice(insert_pos..insert_pos, block_lines);
        }
    } else {
        lines.push(String::new());
        lines.push("trigger:".to_string());
        lines.extend(block_lines);
    }

    let mut result = lines.join("\n");
    if !result.ends_with('\n') {
        result.push('\n');
    }
    result
}

pub fn update_yaml_input_streams(content: &str, streams: &[(String, String)]) -> String {
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();

    let input_idx = lines.iter().position(|l| {
        let t = l.trim();
        t == "input:" || t.starts_with("input:")
    });

    let input_lines: Vec<String> = streams
        .iter()
        .map(|(id, url)| format!("  {}: {}", id, url))
        .collect();

    if let Some(idx) = input_idx {
        let mut end = idx + 1;
        while end < lines.len() {
            let line = &lines[end];
            let trimmed = line.trim();
            if trimmed.is_empty() || (!line.starts_with(' ') && !line.starts_with('\t')) {
                break;
            }
            end += 1;
        }
        lines.splice((idx + 1)..end, input_lines);
    } else {
        let mut new_block = vec!["input:".to_string()];
        new_block.extend(input_lines);
        new_block.push(String::new());
        lines.splice(0..0, new_block);
    }

    let trigger_idx = lines.iter().position(|l| {
        let t = l.trim();
        t == "trigger:" || t.starts_with("trigger:")
    });

    let valid_ids: std::collections::HashSet<&str> =
        streams.iter().map(|(id, _)| id.as_str()).collect();

    if let Some(t_idx) = trigger_idx {
        let mut t_end = t_idx + 1;
        while t_end < lines.len() {
            let line = &lines[t_end];
            let trimmed = line.trim();
            if !trimmed.is_empty() && !line.starts_with(' ') && !line.starts_with('\t') {
                break;
            }
            t_end += 1;
        }

        struct TriggerChild {
            key: String,
            lines: Vec<String>,
        }

        let mut trigger_children: Vec<TriggerChild> = Vec::new();
        let mut leading_lines: Vec<String> = Vec::new();
        let mut curr_child: Option<TriggerChild> = None;

        for line in &lines[(t_idx + 1)..t_end] {
            let trimmed = line.trim();
            let is_child_header = !trimmed.is_empty()
                && (line.starts_with("  ") && !line.starts_with("   "))
                && trimmed.ends_with(':');

            if is_child_header {
                if let Some(c) = curr_child.take() {
                    trigger_children.push(c);
                }
                let key = trimmed.trim_end_matches(':').trim().to_string();
                curr_child = Some(TriggerChild {
                    key,
                    lines: vec![line.clone()],
                });
            } else if let Some(ref mut c) = curr_child {
                c.lines.push(line.clone());
            } else {
                leading_lines.push(line.clone());
            }
        }
        if let Some(c) = curr_child {
            trigger_children.push(c);
        }

        // 1. 保留未被删除的流以及非流配置（如 http_post）
        let mut kept_children: Vec<TriggerChild> = trigger_children
            .into_iter()
            .filter(|c| c.key == "http_post" || valid_ids.contains(c.key.as_str()))
            .collect();

        // 2. 为新加入的流追加默认 trigger 配置
        for (stream_id, _) in streams {
            let already_present = kept_children.iter().any(|c| c.key == *stream_id);
            if !already_present {
                kept_children.push(TriggerChild {
                    key: stream_id.clone(),
                    lines: vec![
                        format!("  {}:", stream_id),
                        "    enabled: true".to_string(),
                        "    trigger_box: [0.050, 0.050, 0.950, 0.950]".to_string(),
                    ],
                });
            }
        }

        let mut new_trigger_lines = leading_lines;
        for child in kept_children {
            new_trigger_lines.extend(child.lines);
        }
        lines.splice((t_idx + 1)..t_end, new_trigger_lines);
    } else {
        lines.push(String::new());
        lines.push("trigger:".to_string());
        for (stream_id, _) in streams {
            lines.push(format!("  {}:", stream_id));
            lines.push("    enabled: true".to_string());
            lines.push("    trigger_box: [0.050, 0.050, 0.950, 0.950]".to_string());
        }
    }

    let mut result = lines.join("\n");
    if !result.ends_with('\n') {
        result.push('\n');
    }
    result
}

pub fn save_input_streams_to_yaml_file<P: AsRef<Path>>(
    path: P,
    streams: &[(String, String)],
) -> std::io::Result<()> {
    let file_path = path.as_ref();
    let content = std::fs::read_to_string(file_path).unwrap_or_default();
    let updated = update_yaml_input_streams(&content, streams);
    std::fs::write(file_path, &updated)?;
    Ok(())
}
