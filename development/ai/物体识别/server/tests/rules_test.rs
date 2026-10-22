use server::object_tracker::{evaluate_rules, DetectionRule, RuleOperator, TrackedObject};

fn make_test_obj(track_id: u64, label: &str, rel_box: [f64; 4]) -> TrackedObject {
    let center = [(rel_box[0] + rel_box[2]) / 2.0, (rel_box[1] + rel_box[3]) / 2.0];
    TrackedObject {
        track_id,
        class_id: Some(track_id as i32),
        label: Some(label.to_string()),
        text: None,
        confidence: 0.9,
        rel_box,
        box_coord: vec![rel_box[0] * 1920.0, rel_box[1] * 1080.0, rel_box[2] * 1920.0, rel_box[3] * 1080.0],
        center,
        trajectory: vec![center],
        hits: 5,
        lost_frames: 0,
        age: 5,
    }
}

#[test]
fn test_bind_missing_hardhat() {
    let rule = DetectionRule {
        id: "r_helmet".to_string(),
        name: "未戴安全帽".to_string(),
        enabled: true,
        operator: RuleOperator::Bind {
            parent_class: "person".to_string(),
            child_class: "hardhat".to_string(),
            min_iou: 0.15,
            trigger_on: "missing".to_string(),
        },
    };

    let p1 = make_test_obj(1, "person", [0.1, 0.1, 0.3, 0.8]);
    let p2 = make_test_obj(2, "person", [0.5, 0.1, 0.7, 0.8]);
    let h2 = make_test_obj(3, "hardhat", [0.55, 0.1, 0.65, 0.25]);

    let objects = vec![p1, p2, h2];
    let in_roi = vec![true, true, true];
    let alerts = evaluate_rules(&objects, &in_roi, &[rule]);

    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].track_id, Some(1));
    assert_eq!(alerts[0].alert_type, "未戴安全帽");
}

#[test]
fn test_proximity_forklift_person() {
    let rule = DetectionRule {
        id: "r_forklift".to_string(),
        name: "人车防撞预警".to_string(),
        enabled: true,
        operator: RuleOperator::Proximity {
            class_a: "forklift".to_string(),
            class_b: "person".to_string(),
            max_distance: 0.2,
        },
    };

    let f1 = make_test_obj(1, "forklift", [0.2, 0.2, 0.4, 0.5]);
    let p1 = make_test_obj(2, "person", [0.35, 0.2, 0.45, 0.5]);
    let p2 = make_test_obj(3, "person", [0.8, 0.2, 0.9, 0.5]);

    let objects = vec![f1, p1, p2];
    let in_roi = vec![true, true, true];
    let alerts = evaluate_rules(&objects, &in_roi, &[rule]);

    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].alert_type, "人车防撞预警");
}

#[test]
fn test_presence_smoking() {
    let rule = DetectionRule {
        id: "r_smoke".to_string(),
        name: "吸烟违规".to_string(),
        enabled: true,
        operator: RuleOperator::Presence {
            target_classes: vec!["smoking".to_string()],
            min_confidence: Some(0.6),
        },
    };

    let s1 = make_test_obj(1, "smoking", [0.2, 0.2, 0.3, 0.3]);
    let p1 = make_test_obj(2, "person", [0.5, 0.2, 0.7, 0.7]);

    let objects = vec![s1, p1];
    let in_roi = vec![true, true];
    let alerts = evaluate_rules(&objects, &in_roi, &[rule]);

    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].alert_type, "吸烟违规");
}

#[test]
fn test_license_plate_recognition() {
    let rule = DetectionRule {
        id: "rule_license_plate_recognition".to_string(),
        name: "车牌抓拍与识别告警".to_string(),
        enabled: true,
        operator: RuleOperator::Presence {
            target_classes: vec!["license_plate".to_string(), "vehicle".to_string()],
            min_confidence: Some(0.6),
        },
    };

    let mut plate_obj = make_test_obj(1, "license_plate", [0.3, 0.4, 0.5, 0.45]);
    plate_obj.text = Some("粤B12345".to_string());

    let objects = vec![plate_obj];
    let in_roi = vec![true];
    let alerts = evaluate_rules(&objects, &in_roi, &[rule]);

    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].alert_type, "车牌抓拍与识别告警");
    assert_eq!(alerts[0].rule_id, "rule_license_plate_recognition");
}
