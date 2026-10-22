use crate::object_tracker::TrackedObject;
use serde::{Deserialize, Serialize};

fn default_true() -> bool {
    true
}

fn default_iou_thresh() -> f64 {
    0.15
}

fn default_trigger_missing() -> String {
    "missing".to_string()
}

fn default_proximity_dist() -> f64 {
    0.15
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum RuleOperator {
    Presence {
        #[serde(default)]
        target_classes: Vec<String>,
        #[serde(default, skip_serializing_if = "Option::is_none")]
        min_confidence: Option<f64>,
    },
    Bind {
        parent_class: String,
        child_class: String,
        #[serde(default = "default_iou_thresh")]
        min_iou: f64,
        #[serde(default = "default_trigger_missing")]
        trigger_on: String,
    },
    Proximity {
        class_a: String,
        class_b: String,
        #[serde(default = "default_proximity_dist")]
        max_distance: f64,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DetectionRule {
    pub id: String,
    pub name: String,
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(flatten)]
    pub operator: RuleOperator,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuleAlert {
    pub rule_id: String,
    pub rule_name: String,
    pub alert_type: String,
    pub track_id: Option<u64>,
    pub label: Option<String>,
    pub class_id: Option<i32>,
    pub confidence: f64,
    pub rel_box: [f64; 4],
    pub box_coord: Vec<f64>,
    pub center: [f64; 2],
    pub detail: String,
}

pub fn calc_box_overlap(box_a: [f64; 4], box_b: [f64; 4]) -> (f64, f64) {
    let x_min = box_a[0].max(box_b[0]);
    let y_min = box_a[1].max(box_b[1]);
    let x_max = box_a[2].min(box_b[2]);
    let y_max = box_a[3].min(box_b[3]);

    let inter_w = (x_max - x_min).max(0.0);
    let inter_h = (y_max - y_min).max(0.0);
    let inter_area = inter_w * inter_h;

    let area_a = (box_a[2] - box_a[0]).max(0.0) * (box_a[3] - box_a[1]).max(0.0);
    let area_b = (box_b[2] - box_b[0]).max(0.0) * (box_b[3] - box_b[1]).max(0.0);

    let union_area = area_a + area_b - inter_area;
    let iou = if union_area > 0.0 { inter_area / union_area } else { 0.0 };
    let coverage_b = if area_b > 0.0 { inter_area / area_b } else { 0.0 };

    (iou, coverage_b)
}

pub fn calc_center_dist(c1: [f64; 2], c2: [f64; 2]) -> f64 {
    let dx = c1[0] - c2[0];
    let dy = c1[1] - c2[1];
    (dx * dx + dy * dy).sqrt()
}

fn class_matches(track: &TrackedObject, target: &str) -> bool {
    if let Some(ref l) = track.label
        && l.eq_ignore_ascii_case(target)
    {
        return true;
    }
    if let Some(cid) = track.class_id
        && cid.to_string() == target
    {
        return true;
    }
    false
}

pub fn evaluate_rules(
    tracked_objects: &[TrackedObject],
    in_roi_flags: &[bool],
    rules: &[DetectionRule],
) -> Vec<RuleAlert> {
    let mut alerts = Vec::new();

    for rule in rules {
        if !rule.enabled {
            continue;
        }

        match &rule.operator {
            RuleOperator::Presence { target_classes, min_confidence } => {
                let conf_thresh = min_confidence.unwrap_or(0.0);
                for (idx, track) in tracked_objects.iter().enumerate() {
                    let in_roi = in_roi_flags.get(idx).copied().unwrap_or(true);
                    if !in_roi || track.confidence < conf_thresh {
                        continue;
                    }

                    let hit = target_classes.is_empty() || target_classes.iter().any(|c| class_matches(track, c));
                    if hit {
                        alerts.push(RuleAlert {
                            rule_id: rule.id.clone(),
                            rule_name: rule.name.clone(),
                            alert_type: rule.name.clone(),
                            track_id: Some(track.track_id),
                            label: track.label.clone(),
                            class_id: track.class_id,
                            confidence: track.confidence,
                            rel_box: track.rel_box,
                            box_coord: track.box_coord.clone(),
                            center: track.center,
                            detail: format!("检测到违规目标: {:?}", track.label),
                        });
                    }
                }
            }

            RuleOperator::Bind { parent_class, child_class, min_iou, trigger_on } => {
                let is_trigger_missing = trigger_on.eq_ignore_ascii_case("missing");

                let mut parents = Vec::new();
                let mut children = Vec::new();

                for (idx, track) in tracked_objects.iter().enumerate() {
                    let in_roi = in_roi_flags.get(idx).copied().unwrap_or(true);
                    if !in_roi {
                        continue;
                    }

                    if class_matches(track, parent_class) {
                        parents.push(track);
                    } else if class_matches(track, child_class) {
                        children.push(track);
                    }
                }

                for parent in parents {
                    let mut bound_child = None;
                    for child in &children {
                        let (iou, coverage) = calc_box_overlap(parent.rel_box, child.rel_box);
                        if coverage >= *min_iou || iou >= *min_iou {
                            bound_child = Some(child);
                            break;
                        }
                    }

                    if is_trigger_missing && bound_child.is_none() {
                        alerts.push(RuleAlert {
                            rule_id: rule.id.clone(),
                            rule_name: rule.name.clone(),
                            alert_type: rule.name.clone(),
                            track_id: Some(parent.track_id),
                            label: parent.label.clone(),
                            class_id: parent.class_id,
                            confidence: parent.confidence,
                            rel_box: parent.rel_box,
                            box_coord: parent.box_coord.clone(),
                            center: parent.center,
                            detail: format!(
                                "目标 {} 未检测到绑定装备 {}",
                                parent.label.as_deref().unwrap_or("person"),
                                child_class
                            ),
                        });
                    } else if !is_trigger_missing && bound_child.is_some() {
                        alerts.push(RuleAlert {
                            rule_id: rule.id.clone(),
                            rule_name: rule.name.clone(),
                            alert_type: rule.name.clone(),
                            track_id: Some(parent.track_id),
                            label: parent.label.clone(),
                            class_id: parent.class_id,
                            confidence: parent.confidence,
                            rel_box: parent.rel_box,
                            box_coord: parent.box_coord.clone(),
                            center: parent.center,
                            detail: format!(
                                "目标 {} 关联违规目标 {}",
                                parent.label.as_deref().unwrap_or("parent"),
                                child_class
                            ),
                        });
                    }
                }
            }

            RuleOperator::Proximity { class_a, class_b, max_distance } => {
                let mut group_a = Vec::new();
                let mut group_b = Vec::new();

                for (idx, track) in tracked_objects.iter().enumerate() {
                    let in_roi = in_roi_flags.get(idx).copied().unwrap_or(true);
                    if !in_roi {
                        continue;
                    }

                    if class_matches(track, class_a) {
                        group_a.push(track);
                    }
                    if class_matches(track, class_b) {
                        group_b.push(track);
                    }
                }

                for obj_a in &group_a {
                    for obj_b in &group_b {
                        if obj_a.track_id == obj_b.track_id {
                            continue;
                        }

                        let dist = calc_center_dist(obj_a.center, obj_b.center);
                        if dist <= *max_distance {
                            let union_box = [
                                obj_a.rel_box[0].min(obj_b.rel_box[0]),
                                obj_a.rel_box[1].min(obj_b.rel_box[1]),
                                obj_a.rel_box[2].max(obj_b.rel_box[2]),
                                obj_a.rel_box[3].max(obj_b.rel_box[3]),
                            ];

                            alerts.push(RuleAlert {
                                rule_id: rule.id.clone(),
                                rule_name: rule.name.clone(),
                                alert_type: rule.name.clone(),
                                track_id: Some(obj_a.track_id),
                                label: obj_a.label.clone(),
                                class_id: obj_a.class_id,
                                confidence: obj_a.confidence.max(obj_b.confidence),
                                rel_box: union_box,
                                box_coord: obj_a.box_coord.clone(),
                                center: obj_a.center,
                                detail: format!(
                                    "人车/目标距离过近危险: {} 与 {} 相对中心距 {:.3} (阈值: {:.3})",
                                    obj_a.label.as_deref().unwrap_or(class_a),
                                    obj_b.label.as_deref().unwrap_or(class_b),
                                    dist,
                                    max_distance
                                ),
                            });
                        }
                    }
                }
            }
        }
    }

    alerts
}
