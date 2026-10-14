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

#[test]
fn test_update_yaml_input_streams_full_with_enabled_toggle() {
    let original = r#"input:
  cam0: rtsp://192.168.88.20:8554/live0
  cam1: rtsp://192.168.88.20:8554/live1

trigger:
  cam0:
    enabled: true
    trigger_box: [0.050, 0.050, 0.950, 0.950]
  cam1:
    enabled: true
    trigger_box: [0.100, 0.100, 0.900, 0.900]
"#;

    let new_streams = vec![
        ("cam0".to_string(), "rtsp://192.168.88.20:8554/live0".to_string(), false),
        ("cam1".to_string(), "rtsp://192.168.88.20:8554/live1".to_string(), true),
    ];

    let updated = server::object_tracker::update_yaml_input_streams_full(original, &new_streams);
    assert!(updated.contains("  cam0:\n    enabled: false"));
    assert!(updated.contains("  cam1:\n    enabled: true"));
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

#[test]
fn test_yaml_config_crud_and_path_binding() {
    use server::config::YamlConfig;

    let tmp_path = "target/test_config.yaml";
    let mut cfg = YamlConfig::new(tmp_path);
    assert_eq!(cfg.path(), std::path::Path::new(tmp_path));

    cfg.set_string("server_name", "test_app");
    cfg.set_u64("port", 9090);
    cfg.set_bool("debug", true);

    assert_eq!(cfg.get_str("server_name"), Some("test_app"));
    assert_eq!(cfg.get_u64("port"), Some(9090));
    assert_eq!(cfg.get_bool("debug"), Some(true));

    cfg.set_nested(&["section", "sub", "key"], serde_yaml::Value::String("val".into()));
    assert_eq!(
        cfg.get_nested(&["section", "sub", "key"]).and_then(|v| v.as_str()),
        Some("val")
    );

    cfg.set_alert_url(Some("http://127.0.0.1:8080/hook"));
    cfg.set_alert_cooldown_sec(Some(10));
    cfg.set_alert_timeout_sec(Some(3));

    assert_eq!(cfg.get_alert_url().as_deref(), Some("http://127.0.0.1:8080/hook"));
    assert_eq!(cfg.get_alert_cooldown_sec(), Some(10));
    assert_eq!(cfg.get_alert_timeout_sec(), Some(3));

    let (url, cd, to) = cfg.get_alert();
    assert_eq!(url.as_deref(), Some("http://127.0.0.1:8080/hook"));
    assert_eq!(cd, Some(10));
    assert_eq!(to, Some(3));

    cfg.set_server_host("127.0.0.1");
    cfg.set_server_port(8088);
    assert_eq!(cfg.get_server_host().as_deref(), Some("127.0.0.1"));
    assert_eq!(cfg.get_server_port(), Some(8088));

    cfg.set_input_streams(&[
        ("cam1".to_string(), "rtsp://127.0.0.1/live1".to_string()),
    ]);
    let streams = cfg.get_input_streams();
    assert_eq!(streams.len(), 1);
    assert_eq!(streams[0].0, "cam1");

    assert!(cfg.save().is_ok());
    let loaded = YamlConfig::load_from_file(tmp_path).unwrap();
    assert_eq!(loaded.get_str("server_name"), Some("test_app"));
    assert_eq!(loaded.get_u64("port"), Some(9090));
    assert_eq!(loaded.get_server_host().as_deref(), Some("127.0.0.1"));
    assert_eq!(loaded.get_server_port(), Some(8088));

    let _ = std::fs::remove_file(tmp_path);
}

#[test]
fn test_yaml_config_formatting_has_blank_lines() {
    use server::config::YamlConfig;

    let mut cfg = YamlConfig::new("target/format_test.yaml");
    cfg.set_input_streams(&[
        ("test_s1".to_string(), "rtsp://127.0.0.1:8554/live1".to_string()),
    ]);
    cfg.set_server_host("0.0.0.0");
    cfg.set_server_port(8181);
    cfg.set_alert(Some("http://127.0.0.1:4000/api/alert"), Some(2), Some(5));

    let formatted = cfg.to_formatted_yaml().unwrap();
    println!("formatted output:\n{}", formatted);

    assert!(formatted.contains("input:\n  test_s1: rtsp://127.0.0.1:8554/live1\n\nserver:"));
    assert!(formatted.contains("alert:\n  url: http://127.0.0.1:4000/api/alert\n  cooldown_sec: 2\n  timeout_sec: 5"));
    assert!(!formatted.contains("input: null"));
    assert!(!formatted.contains("trigger: null"));
}

#[test]
fn test_update_yaml_empty_streams_removes_input_and_trigger() {
    let original = r#"input:
  aaa: rtsp://192.168.88.20:8554/file_01

server:
  host: "0.0.0.0"
  port: 8181

alert:
  url: http://127.0.0.1:4000/api/alert
  cooldown_sec: 2
  timeout_sec: 5

trigger:
  aaa:
    enabled: true
    trigger_box: [0.050, 0.050, 0.950, 0.950]
"#;

    let updated = server::object_tracker::update_yaml_input_streams_full(original, &[]);
    assert!(!updated.contains("input:"));
    assert!(!updated.contains("input: null"));
    assert!(!updated.contains("trigger:"));
    assert!(!updated.contains("trigger: null"));
    assert!(updated.contains("server:\n  host: \"0.0.0.0\""));
    assert!(updated.contains("alert:\n  url: http://127.0.0.1:4000/api/alert"));
}





