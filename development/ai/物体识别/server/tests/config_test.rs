use tokio::sync::Mutex;

static TEST_MUTEX: Mutex<()> = Mutex::const_new(());

#[test]
fn test_update_input_streams() {
    let original = r#"input:
  aaa: rtsp://192.168.88.20:8554/file_01
  bbb: rtsp://192.168.88.20:8554/file_02

server:
  host: "0.0.0.0"
  port: 8181

trigger:
  aaa:
    enabled: true
    roi: [0.050, 0.050, 0.950, 0.950]
"#;

    let new_streams = vec![
        ("aaa".to_string(), "rtsp://192.168.88.20:8554/live_a".to_string()),
        ("ccc".to_string(), "rtsp://192.168.88.20:8554/live_c".to_string()),
    ];

    let updated = server::config::input::update_input_streams(original, &new_streams);
    assert!(updated.contains("  aaa: rtsp://192.168.88.20:8554/live_a"));
    assert!(updated.contains("  ccc: rtsp://192.168.88.20:8554/live_c"));
    assert!(!updated.contains("  bbb: rtsp://192.168.88.20:8554/file_02"));
    assert!(updated.contains("host: 0.0.0.0") || updated.contains("host: \"0.0.0.0\""));
    assert!(updated.contains("  ccc:\n    enabled: true"));
}

#[test]
fn test_update_delete_stream_also_deletes_trigger() {
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
    roi: [0.014, 0.053, 0.277, 0.931]
  bbb:
    enabled: true
    roi: [0.781, 0.020, 0.978, 0.968]
  ccc:
    enabled: true
    roi: [0.462, 0.616, 0.805, 0.803]
"#;

    let new_streams = vec![
        ("aaa".to_string(), "rtsp://192.168.88.20:8554/file_01".to_string()),
        ("bbb".to_string(), "rtsp://192.168.88.20:8554/file_02".to_string()),
    ];

    let updated = server::config::input::update_input_streams(original, &new_streams);
    assert!(updated.contains("  aaa: rtsp://192.168.88.20:8554/file_01"));
    assert!(updated.contains("  bbb: rtsp://192.168.88.20:8554/file_02"));
    assert!(!updated.contains("  ccc: rtsp://192.168.88.20:8554/file_03"));
    assert!(updated.contains("  aaa:\n    enabled: true\n    roi: [0.014, 0.053, 0.277, 0.931]"));
    assert!(updated.contains("  bbb:\n    enabled: true\n    roi: [0.781, 0.020, 0.978, 0.968]"));
    assert!(!updated.contains("  ccc:"));
    assert!(!updated.contains("[0.462, 0.616, 0.805, 0.803]"));
}

#[test]
fn test_update_input_streams_full_with_enabled_toggle() {
    let original = r#"input:
  cam0: rtsp://192.168.88.20:8554/live0
  cam1: rtsp://192.168.88.20:8554/live1

trigger:
  cam0:
    enabled: true
    roi: [0.050, 0.050, 0.950, 0.950]
  cam1:
    enabled: true
    roi: [0.100, 0.100, 0.900, 0.900]
"#;

    let new_streams = vec![
        ("cam0".to_string(), "rtsp://192.168.88.20:8554/live0".to_string(), false),
        ("cam1".to_string(), "rtsp://192.168.88.20:8554/live1".to_string(), true),
    ];

    let updated = server::config::input::update_input_streams_full(original, &new_streams);
    assert!(updated.contains("  cam0:\n    enabled: false"));
    assert!(updated.contains("  cam1:\n    enabled: true"));
}

#[tokio::test]
async fn test_update_alert_url_and_config() {
    let _guard = TEST_MUTEX.lock().await;
    let test_url = "http://192.168.88.1:4000/api/alert";
    let res = server::updater::update_alert_url(test_url).await;
    assert!(res.is_ok());
    assert_eq!(server::updater::get_alert_url(), test_url);

    let res2 = server::updater::update_alert_config(Some("http://127.0.0.1:4000/api/alert"), Some(2), Some(5)).await;
    assert!(res2.is_ok());
    assert_eq!(server::updater::get_alert_url(), "http://127.0.0.1:4000/api/alert");
    assert_eq!(server::updater::get_alert_cooldown_sec(), Some(2));
    assert_eq!(server::updater::get_alert_timeout_sec(), Some(5));

    let alert_cfg = server::config::alert::load_config();
    assert_eq!(alert_cfg.url.as_deref(), Some("http://127.0.0.1:4000/api/alert"));
    assert_eq!(alert_cfg.cooldown_sec, Some(2));
    assert_eq!(alert_cfg.timeout_sec, Some(5));
}

#[test]
fn test_yaml_config_crud_and_path_binding() {
    let _guard = TEST_MUTEX.blocking_lock();
    use ::server::config::{self, YamlConfig};

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

    config::alert::apply_to_yaml(Some("http://127.0.0.1:8080/hook"), Some(10), Some(3), &mut cfg);

    let alert = config::alert::from_yaml(&cfg);
    assert_eq!(alert.url.as_deref(), Some("http://127.0.0.1:8080/hook"));
    assert_eq!(alert.cooldown_sec, Some(10));
    assert_eq!(alert.timeout_sec, Some(3));

    config::server::apply_to_yaml("127.0.0.1", 8088, &mut cfg);
    let srv = config::server::from_yaml(&cfg);
    assert_eq!(srv.host, "127.0.0.1");
    assert_eq!(srv.port, 8088);

    config::input::apply_to_yaml_pairs(&[
        ("cam1".to_string(), "rtsp://127.0.0.1/live1".to_string()),
    ], &mut cfg);
    let streams = config::input::from_yaml(&cfg);
    assert_eq!(streams[0].id, "cam1");
    assert_eq!(streams[0].input, "rtsp://127.0.0.1/live1");

    assert!(cfg.save().is_ok());
    let loaded = YamlConfig::load_from_file(tmp_path).unwrap();
    assert_eq!(loaded.get_str("server_name"), Some("test_app"));
    assert_eq!(loaded.get_u64("port"), Some(9090));
    let srv_loaded = config::server::from_yaml(&loaded);
    assert_eq!(srv_loaded.host, "127.0.0.1");
    assert_eq!(srv_loaded.port, 8088);

    let _ = std::fs::remove_file(tmp_path);
}

#[test]
fn test_yaml_config_formatting_has_blank_lines() {
    use ::server::config::{self, YamlConfig};

    let mut cfg = YamlConfig::new("target/format_test.yaml");
    config::input::apply_to_yaml_pairs(&[
        ("test_s1".to_string(), "rtsp://127.0.0.1:8554/live1".to_string()),
    ], &mut cfg);
    config::server::apply_to_yaml("0.0.0.0", 8181, &mut cfg);
    config::alert::apply_to_yaml(Some("http://127.0.0.1:4000/api/alert"), Some(2), Some(5), &mut cfg);

    let formatted = cfg.format().unwrap();
    println!("formatted output:\n{}", formatted);

    assert!(formatted.contains("input:\n  test_s1: rtsp://127.0.0.1:8554/live1\n\nserver:"));
    assert!(formatted.contains("alert:\n  url: http://127.0.0.1:4000/api/alert\n  cooldown_sec: 2\n  timeout_sec: 5"));
    assert!(!formatted.contains("input: null"));
    assert!(!formatted.contains("trigger: null"));
}

#[test]
fn test_update_empty_streams_removes_input_and_trigger() {
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
    roi: [0.050, 0.050, 0.950, 0.950]
"#;

    let updated = server::config::input::update_input_streams_full(original, &[]);
    assert!(!updated.contains("input:"));
    assert!(!updated.contains("input: null"));
    assert!(!updated.contains("trigger:"));
    assert!(!updated.contains("trigger: null"));
    assert!(updated.contains("host: 0.0.0.0") || updated.contains("host: \"0.0.0.0\""));
    assert!(updated.contains("alert:\n  url: http://127.0.0.1:4000/api/alert"));
}

#[test]
fn test_update_stream_zone_global_shared() {
    let original = r#"server:
  host: "0.0.0.0"
  port: 8181

trigger:
"#;

    let cfg = server::config::ZoneConfig {
        target_classes: vec!["smoking".to_string(), "fire".to_string()],
        roi: Some(server::object_tracker::RoiConfig::Rect([0.1, 0.2, 0.8, 0.9])),
        ..Default::default()
    };

    let updated = server::config::channel::update_stream_zone(original, "cam1", &cfg);
    assert!(updated.contains("trigger:\n  target_classes: [\"smoking\",\"fire\"]"));
    assert!(updated.contains("  cam1:\n    enabled: true\n    roi: [0.100, 0.200, 0.800, 0.900]"));
    assert!(!updated.contains("    target_classes:"));
}

#[test]
fn test_update_global_detection_independent() {
    let original = r#"server:
  host: "0.0.0.0"
  port: 8181

trigger:
  cam1:
    enabled: true
    roi: [0.100, 0.200, 0.800, 0.900]
"#;

    let target_classes = vec!["smoking".to_string(), "person".to_string()];
    let updated = server::config::trigger::update_global_detection(original, &target_classes, &[]);
    assert!(updated.contains("target_classes: [\"smoking\",\"person\"]"));
    assert!(updated.contains("  cam1:\n    enabled: true\n    roi: [0.100, 0.200, 0.800, 0.900]"));
}

#[test]
fn test_channel_spacing_under_trigger() {
    let original = r#"server:
  host: "0.0.0.0"
  port: 8181

trigger:
"#;

    let cfg1 = server::config::ZoneConfig {
        target_classes: vec!["smoking".to_string()],
        roi: Some(server::object_tracker::RoiConfig::Rect([0.1, 0.2, 0.8, 0.9])),
        ..Default::default()
    };

    let s1 = server::config::channel::update_channel_zone(original, "cam1", &cfg1);

    let cfg2 = server::config::ZoneConfig {
        roi: Some(server::object_tracker::RoiConfig::Rect([0.3, 0.4, 0.5, 0.6])),
        ..Default::default()
    };

    let s2 = server::config::channel::update_channel_zone(&s1, "cam2", &cfg2);

    println!("FORMATTED MULTI-CHANNEL YAML:\n{}", s2);
    assert!(s2.contains("\n\n  cam1:"));
    assert!(s2.contains("\n\n  cam2:"));
}

#[test]
fn test_domain_config_modules() {
    let _guard = TEST_MUTEX.blocking_lock();
    use ::server::config::{self, ZoneConfig, YamlConfig};
    let tmp_path = "target/domain_config_test.yaml";
    let _ = std::fs::remove_file(tmp_path);

    assert_eq!(config::DEFAULT_CONFIG_PATH, "config.yaml");
    assert_eq!(config::get_config_path(), "config.yaml");

    let mut cfg = YamlConfig::new(tmp_path);

    config::server::apply_to_yaml("192.168.1.100", 9999, &mut cfg);
    let srv = config::server::from_yaml(&cfg);
    assert_eq!(srv.host, "192.168.1.100");
    assert_eq!(srv.port, 9999);

    let streams = vec![
        config::StreamConfig {
            id: "ch1".to_string(),
            input: "rtsp://camera1/stream".to_string(),
            enabled: true,
            model: "industry".to_string(),
        },
        config::StreamConfig {
            id: "ch2".to_string(),
            input: "rtsp://camera2/stream".to_string(),
            enabled: false,
            model: "industry".to_string(),
        },
    ];
    config::input::apply_to_yaml(&streams, &mut cfg);
    let loaded_streams = config::input::from_yaml(&cfg);
    assert_eq!(loaded_streams.len(), 2);
    assert_eq!(loaded_streams[0].id, "ch1");
    assert_eq!(loaded_streams[0].input, "rtsp://camera1/stream");
    assert!(loaded_streams[0].enabled);
    assert_eq!(loaded_streams[1].id, "ch2");
    assert_eq!(loaded_streams[1].input, "rtsp://camera2/stream");
    assert!(!loaded_streams[1].enabled);

    let target_classes = vec!["person".to_string(), "vehicle".to_string()];
    let rules = vec![::server::object_tracker::rules::DetectionRule {
        id: "r1".to_string(),
        name: "person_rule".to_string(),
        enabled: true,
        operator: ::server::object_tracker::rules::RuleOperator::Presence {
            target_classes: vec!["person".to_string()],
            min_confidence: Some(0.5),
        },
    }];
    config::trigger::apply_to_yaml(&target_classes, &rules, &mut cfg);
    let trig = config::trigger::from_yaml(&cfg);
    assert_eq!(trig.target_classes, target_classes);
    assert_eq!(trig.rules.len(), 1);
    assert_eq!(trig.rules[0].name, "person_rule");

    let ch1_zone = ZoneConfig {
        enabled: true,
        roi: Some(::server::config::RoiConfig::Rect([0.15, 0.25, 0.75, 0.85])),
        ..Default::default()
    };
    config::channel::apply_to_yaml("ch1", &ch1_zone, &mut cfg);

    let loaded_ch1 = config::channel::from_yaml(&cfg, "ch1");
    assert!(loaded_ch1.enabled);
    assert_eq!(loaded_ch1.roi, Some(::server::config::RoiConfig::Rect([0.15, 0.25, 0.75, 0.85])));

    let all_zones = config::channel::from_yaml_all(&cfg);
    assert!(all_zones.contains_key("ch1"));
    assert!(all_zones.contains_key("ch2"));

    config::alert::apply_to_yaml(Some("http://alert.server/api"), Some(15), Some(5), &mut cfg);
    let alert = config::alert::from_yaml(&cfg);
    assert_eq!(alert.url.as_deref(), Some("http://alert.server/api"));
    assert_eq!(alert.cooldown_sec, Some(15));
    assert_eq!(alert.timeout_sec, Some(5));

    assert!(cfg.save().is_ok());

    let loaded_from_disk = YamlConfig::load_from_file(tmp_path).unwrap();
    assert_eq!(config::server::from_yaml(&loaded_from_disk).port, 9999);
    assert_eq!(config::input::from_yaml(&loaded_from_disk).len(), 2);
    assert_eq!(config::trigger::from_yaml(&loaded_from_disk).target_classes.len(), 2);
    assert!(config::channel::from_yaml_all(&loaded_from_disk).contains_key("ch1"));

    let _ = std::fs::remove_file(tmp_path);
}

#[test]
fn test_multi_model_stream_config() {
    use ::server::config::{self, YamlConfig};
    let tmp_path = "test_multi_model_tmp.yaml";
    let _ = std::fs::remove_file(tmp_path);

    let mut cfg = YamlConfig::new(tmp_path);
    let streams = vec![
        config::StreamConfig {
            id: "camera_ppe".to_string(),
            input: "rtsp://192.168.1.10:8554/ppe".to_string(),
            enabled: true,
            model: "safety_ppe".to_string(),
        },
        config::StreamConfig {
            id: "camera_forklift".to_string(),
            input: "rtsp://192.168.1.11:8554/forklift".to_string(),
            enabled: true,
            model: "forklift_collision".to_string(),
        },
        config::StreamConfig {
            id: "camera_steel".to_string(),
            input: "rtsp://192.168.1.12:8554/steel".to_string(),
            enabled: false,
            model: "steel_defect".to_string(),
        },
    ];

    config::input::apply_to_yaml(&streams, &mut cfg);
    assert!(cfg.save().is_ok());

    let loaded = YamlConfig::load_from_file(tmp_path).unwrap();
    let loaded_streams = config::input::from_yaml(&loaded);
    assert_eq!(loaded_streams.len(), 3);
    assert_eq!(loaded_streams[0].id, "camera_forklift");
    assert_eq!(loaded_streams[0].model, "forklift_collision");
    assert_eq!(loaded_streams[1].id, "camera_ppe");
    assert_eq!(loaded_streams[1].model, "safety_ppe");
    assert_eq!(loaded_streams[2].id, "camera_steel");
    assert_eq!(loaded_streams[2].model, "steel_defect");
    assert!(!loaded_streams[2].enabled);

    let _ = std::fs::remove_file(tmp_path);
}







