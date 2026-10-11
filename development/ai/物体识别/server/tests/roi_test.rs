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
