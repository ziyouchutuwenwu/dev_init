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
        "roi": {
            "type": "polygon",
            "coords": [[0.1, 0.1], [0.5, 0.5], [0.8, 0.2]]
        },
        "target_classes": ["person", "car"]
    }"#;

    let zone_obj: Result<server::web::api::objects::ZoneObject, _> = serde_json::from_str(json_data);
    assert!(zone_obj.is_ok());
    let zone_obj = zone_obj.unwrap();
    assert!(zone_obj.enabled);
    assert!(matches!(zone_obj.roi, Some(server::web::api::objects::RoiObject::Polygon(_))));
    assert_eq!(zone_obj.target_classes, vec!["person", "car"]);

    let zone_cfg = server::config::ZoneConfig::try_from(zone_obj).unwrap();
    assert!(zone_cfg.enabled);
    assert!(matches!(zone_cfg.roi, Some(RoiConfig::Polygon(_))));
}

#[test]
fn test_polygon_roi_degenerate_fallback_false() {
    let empty_roi = RoiConfig::Polygon(vec![]);
    assert!(!empty_roi.contains_point([0.5, 0.5]));

    let line_roi = RoiConfig::Polygon(vec![[0.0, 0.0], [1.0, 1.0]]);
    assert!(!line_roi.contains_point([0.5, 0.5]));
}

#[test]
fn test_zone_object_rejects_insufficient_polygon_vertices() {
    let zone_obj = server::web::api::objects::ZoneObject {
        enabled: true,
        roi: Some(server::web::api::objects::RoiObject::Polygon(vec![[0.0, 0.0], [1.0, 1.0]])),
        trigger_line: None,
        target_classes: vec![],
        rules: vec![],
    };
    let res = server::config::ZoneConfig::try_from(zone_obj);
    assert!(res.is_err());
}

#[test]
fn test_roi_object_bare_array_deserialization() {
    let bare_rect = r#"[0.1, 0.2, 0.8, 0.9]"#;
    let roi: server::web::api::objects::RoiObject = serde_json::from_str(bare_rect).unwrap();
    assert_eq!(roi, server::web::api::objects::RoiObject::Rect([0.1, 0.2, 0.8, 0.9]));
}
