use server::object_tracker::RoiConfig;

#[test]
fn test_rect_roi() {
    let roi = RoiConfig::Rect([0.2, 0.2, 0.8, 0.8]);
    assert!(roi.contains_point([0.5, 0.5]));
    assert!(roi.contains_point([0.2, 0.2]));
    assert!(!roi.contains_point([0.1, 0.5]));
    assert!(!roi.contains_point([0.5, 0.9]));
}

#[test]
fn test_polygon_roi() {
    let roi = RoiConfig::Polygon(vec![[0.0, 0.0], [1.0, 0.0], [0.5, 1.0]]);
    assert!(roi.contains_point([0.5, 0.2]));
    assert!(!roi.contains_point([0.1, 0.8]));
}

#[test]
fn test_polygon_zone_config_deserialization() {
    let json_data = r#"{
        "enabled": true,
        "trigger_box": [[0.1, 0.1], [0.5, 0.5], [0.8, 0.2]],
        "roi": {
            "type": "polygon",
            "coords": [[0.1, 0.1], [0.5, 0.5], [0.8, 0.2]]
        },
        "target_classes": ["person", "car"]
    }"#;

    let zone: Result<server::object_tracker::ZoneConfig, _> = serde_json::from_str(json_data);
    assert!(zone.is_ok(), "多边形格式下的 trigger_box 不应导致反序列化失败");
    let zone = zone.unwrap();
    assert!(zone.enabled);
    assert_eq!(zone.trigger_box, None);
    assert!(matches!(zone.roi, Some(RoiConfig::Polygon(_))));
    assert_eq!(zone.target_classes, vec!["person", "car"]);
}
