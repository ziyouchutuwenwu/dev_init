use server::object_tracker::update_yaml_input_streams;

#[test]
fn test_update_yaml_input_streams() {
    let original = r#"input:
  aaa: rtsp://192.168.88.20:8554/file_01
  bbb: rtsp://192.168.88.20:8554/file_02

server:
  host: "0.0.0.0"
  port: 8181

trigger:
  aaa:
    enabled: true
    trigger_box: [0.050, 0.050, 0.950, 0.950]
"#;

    let new_streams = vec![
        ("aaa".to_string(), "rtsp://192.168.88.20:8554/live_a".to_string()),
        ("ccc".to_string(), "rtsp://192.168.88.20:8554/live_c".to_string()),
    ];

    let updated = update_yaml_input_streams(original, &new_streams);
    assert!(updated.contains("  aaa: rtsp://192.168.88.20:8554/live_a"));
    assert!(updated.contains("  ccc: rtsp://192.168.88.20:8554/live_c"));
    assert!(!updated.contains("  bbb: rtsp://192.168.88.20:8554/file_02"));
    assert!(updated.contains("server:\n  host: \"0.0.0.0\""));
    assert!(updated.contains("  ccc:\n    enabled: true"));
}

#[test]
fn test_update_yaml_delete_stream_also_deletes_trigger() {
    let original = r#"input:
  aaa: rtsp://192.168.88.20:8554/file_01
  bbb: rtsp://192.168.88.20:8554/file_02
  ccc: rtsp://192.168.88.20:8554/file_03

server:
  host: "0.0.0.0"
  port: 8181

trigger:
  aaa:
    enabled: true
    trigger_box: [0.014, 0.053, 0.277, 0.931]
  bbb:
    enabled: true
    trigger_box: [0.781, 0.020, 0.978, 0.968]
  ccc:
    enabled: true
    trigger_box: [0.462, 0.616, 0.805, 0.803]
"#;

    let new_streams = vec![
        ("aaa".to_string(), "rtsp://192.168.88.20:8554/file_01".to_string()),
        ("bbb".to_string(), "rtsp://192.168.88.20:8554/file_02".to_string()),
    ];

    let updated = update_yaml_input_streams(original, &new_streams);
    assert!(updated.contains("  aaa: rtsp://192.168.88.20:8554/file_01"));
    assert!(updated.contains("  bbb: rtsp://192.168.88.20:8554/file_02"));
    assert!(!updated.contains("  ccc: rtsp://192.168.88.20:8554/file_03"));
    assert!(updated.contains("  aaa:\n    enabled: true\n    trigger_box: [0.014, 0.053, 0.277, 0.931]"));
    assert!(updated.contains("  bbb:\n    enabled: true\n    trigger_box: [0.781, 0.020, 0.978, 0.968]"));
    assert!(!updated.contains("  ccc:"));
    assert!(!updated.contains("[0.462, 0.616, 0.805, 0.803]"));
}

#[tokio::test]
async fn test_update_alert_url_and_config() {
    let test_url = "http://192.168.88.1:4000/api/alert";
    let res = server::updater::update_alert_url(test_url).await;
    assert!(res.is_ok());
    assert_eq!(server::updater::get_alert_url(), test_url);

    let res2 = server::updater::update_alert_config(Some("http://127.0.0.1:4000/api/alert"), Some(2), Some(5)).await;
    assert!(res2.is_ok());
    assert_eq!(server::updater::get_alert_url(), "http://127.0.0.1:4000/api/alert");
    assert_eq!(server::updater::get_alert_cooldown_sec(), Some(2));
    assert_eq!(server::updater::get_alert_timeout_sec(), Some(5));
}
