use server::object_tracker::{DetectionInput, ObjectTracker};

#[test]
fn test_tracker_assigns_and_maintains_id() {
    let mut tracker = ObjectTracker::new();

    let frame1 = vec![DetectionInput {
        class_id: Some(0),
        label: Some("defect".to_string()),
        confidence: 0.9,
        rel_box: [0.1, 0.1, 0.2, 0.2],
        box_coord: vec![100.0, 100.0, 200.0, 200.0],
    }];
    let tracked1 = tracker.update(frame1);
    assert_eq!(tracked1.len(), 1);
    let id1 = tracked1[0].track_id;
    assert_eq!(tracked1[0].trajectory.len(), 1);

    let frame2 = vec![DetectionInput {
        class_id: Some(0),
        label: Some("defect".to_string()),
        confidence: 0.92,
        rel_box: [0.12, 0.12, 0.22, 0.22],
        box_coord: vec![120.0, 120.0, 220.0, 220.0],
    }];
    let tracked2 = tracker.update(frame2);
    assert_eq!(tracked2.len(), 1);
    assert_eq!(tracked2[0].track_id, id1);
    assert_eq!(tracked2[0].trajectory.len(), 2);

    let frame3 = vec![
        DetectionInput {
            class_id: Some(0),
            label: Some("defect".to_string()),
            confidence: 0.95,
            rel_box: [0.14, 0.14, 0.24, 0.24],
            box_coord: vec![140.0, 140.0, 240.0, 240.0],
        },
        DetectionInput {
            class_id: Some(1),
            label: Some("part".to_string()),
            confidence: 0.88,
            rel_box: [0.5, 0.5, 0.6, 0.6],
            box_coord: vec![500.0, 500.0, 600.0, 600.0],
        },
    ];
    let tracked3 = tracker.update(frame3);
    assert_eq!(tracked3.len(), 2);
    let t1 = tracked3.iter().find(|t| t.track_id == id1).unwrap();
    assert_eq!(t1.trajectory.len(), 3);
    let t2 = tracked3.iter().find(|t| t.track_id != id1).unwrap();
    assert_ne!(t2.track_id, id1);
}
