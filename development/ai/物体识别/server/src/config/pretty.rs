use super::r#const::*;

fn format_number_flow(items: &[&str]) -> Option<String> {
    if items.is_empty() || items.len() > 16 {
        return None;
    }
    if !items.iter().all(|s| s.parse::<f64>().is_ok()) {
        return None;
    }
    let nums: Vec<f64> = items.iter().map(|s| s.parse::<f64>().unwrap()).collect();
    let has_dot = items.iter().any(|s| s.contains('.'));
    let formatted: Vec<String> = nums
        .iter()
        .map(|n| {
            if n.fract() == 0.0 && !has_dot {
                format!("{}", *n as i64)
            } else {
                format!("{:.3}", n)
            }
        })
        .collect();
    Some(format!("[{}]", formatted.join(", ")))
}

fn format_string_flow(items: &[&str]) -> Option<String> {
    if items.is_empty() {
        return None;
    }
    let all_strings = items.iter().all(|s| !s.is_empty() && !s.contains(':') && s.parse::<f64>().is_err());
    if !all_strings {
        return None;
    }
    let clean: Vec<String> = items
        .iter()
        .map(|s| s.trim_matches('"').trim_matches('\'').to_string())
        .collect();
    serde_json::to_string(&clean).ok()
}

fn try_collapse_items(line: &str, items: &[&str]) -> Option<String> {
    let key_indent_len = line.len() - line.trim_start().len();
    let indent = &line[..key_indent_len];
    let key = line.trim().trim_end_matches(':');

    if let Some(num_str) = format_number_flow(items) {
        return Some(format!("{}{}: {}", indent, key, num_str));
    }
    if let Some(str_str) = format_string_flow(items) {
        return Some(format!("{}{}: {}", indent, key, str_str));
    }
    None
}

fn collect_list_items<'a>(raw_lines: &'a [&'a str], start: usize, key_indent: usize) -> (Vec<&'a str>, usize) {
    let mut end = start;
    let mut items = Vec::new();

    while end < raw_lines.len() {
        let line = raw_lines[end];
        let trimmed = line.trim();
        if trimmed.is_empty() {
            end += 1;
            continue;
        }
        let indent_len = line.len() - line.trim_start().len();
        if indent_len >= key_indent && trimmed.starts_with("- ") {
            let item = trimmed[2..].trim();
            if item.contains(':') {
                break;
            }
            items.push(item);
            end += 1;
        } else {
            break;
        }
    }
    (items, end)
}

pub fn prettify_flow_sequences(yaml: &str) -> Vec<String> {
    let raw_lines: Vec<&str> = yaml.lines().collect();
    let mut collapsed = Vec::new();
    let mut idx = 0;

    while idx < raw_lines.len() {
        let line = raw_lines[idx];
        let trimmed = line.trim();

        if trimmed.ends_with(':') && !trimmed.starts_with('-') && idx + 1 < raw_lines.len() {
            let indent_len = line.len() - line.trim_start().len();
            let (items, next_idx) = collect_list_items(&raw_lines, idx + 1, indent_len);
            if !items.is_empty()
                && let Some(collapsed_line) = try_collapse_items(line, &items)
            {
                collapsed.push(collapsed_line);
                idx = next_idx;
                continue;
            }
        }

        collapsed.push(line.to_string());
        idx += 1;
    }

    collapsed
}

fn should_skip_empty_node(line: &str, next_line: Option<&str>) -> bool {
    let trimmed = line.trim();
    if trimmed.ends_with(": null") {
        return true;
    }
    if trimmed.ends_with(':') && !trimmed.starts_with('-') {
        let has_child = next_line
            .map(|l| l.starts_with("  ") || l.starts_with('\t'))
            .unwrap_or(false);
        if !has_child {
            return true;
        }
    }
    false
}

fn is_top_level_section(line: &str) -> bool {
    !line.starts_with(' ') && !line.starts_with('\t') && !line.starts_with('-') && line.contains(':')
}

fn is_sub_block(line: &str) -> bool {
    let trimmed = line.trim();
    line.starts_with("  ")
        && !line.starts_with("   ")
        && !line.starts_with("  -")
        && trimmed.ends_with(':')
        && !trimmed.starts_with(KEY_TARGET_CLASSES)
        && !trimmed.starts_with(KEY_RULES)
}

pub fn prettify_sections(collapsed_lines: &[String]) -> String {
    let mut out = String::new();

    for (i, line) in collapsed_lines.iter().enumerate() {
        let next_line = collapsed_lines.get(i + 1).map(|s| s.as_str());
        if should_skip_empty_node(line, next_line) {
            continue;
        }

        if is_top_level_section(line) {
            if i > 0 && !out.ends_with("\n\n") && !out.is_empty() {
                out.push('\n');
            }
        } else if is_sub_block(line) && !out.ends_with("\n\n") {
            out.push('\n');
        }

        out.push_str(line);
        out.push('\n');
    }

    out
}

pub fn prettify_yaml(yaml: &str) -> String {
    let collapsed = prettify_flow_sequences(yaml);
    prettify_sections(&collapsed)
}
