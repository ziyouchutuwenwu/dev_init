use server::web::WebServer;
use server::web_rtc::WebRtcServer;
use std::sync::Arc;
use tokio::net::TcpListener;

#[tokio::test]
async fn test_options_and_health() {
    let detect_wrapper = Arc::new(server::detector::DetectWrapper::new());
    let server = Arc::new(WebRtcServer::new("0.0.0.0:8181", detect_wrapper, vec![]));
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        let _ = WebServer::run_with_listener(server, listener).await;
    });

    let client = reqwest::Client::new();

    let res = client
        .get(format!("http://{addr}/health"))
        .send()
        .await
        .unwrap();
    assert_eq!(res.status(), reqwest::StatusCode::OK);
    assert_eq!(res.text().await.unwrap(), "ok");

    let res_options = client
        .request(reqwest::Method::OPTIONS, format!("http://{addr}/api/streams"))
        .header("Origin", "http://localhost:4000")
        .header("Access-Control-Request-Method", "POST")
        .send()
        .await
        .unwrap();
    assert_eq!(res_options.status(), reqwest::StatusCode::OK);
    assert!(res_options.headers().contains_key("access-control-allow-origin"));

    let res_404 = client
        .get(format!("http://{addr}/unknown/route"))
        .send()
        .await
        .unwrap();
    assert_eq!(res_404.status(), reqwest::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn test_post_streams_hot_update() {
    let detect_wrapper = Arc::new(server::detector::DetectWrapper::new());
    let server = Arc::new(WebRtcServer::new("0.0.0.0:8181", detect_wrapper, vec![]));
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    let srv_clone = Arc::clone(&server);
    tokio::spawn(async move {
        let _ = WebServer::run_with_listener(srv_clone, listener).await;
    });

    let client = reqwest::Client::new();

    assert!(server.stream_order().is_empty());

    let res = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[{"id":"test_s1","url":"rtsp://127.0.0.1:8554/live1"}]}"#)
        .send()
        .await
        .unwrap();

    assert_eq!(res.status(), reqwest::StatusCode::OK);
    assert_eq!(server.stream_order(), vec!["test_s1"]);
    assert!(server.has_stream("test_s1"));
    assert_eq!(server.get_stream_ai_enabled("test_s1"), Some(true));

    let res_disable = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[{"id":"test_s1","url":"rtsp://127.0.0.1:8554/live1","enabled":false}]}"#)
        .send()
        .await
        .unwrap();
    assert_eq!(res_disable.status(), reqwest::StatusCode::OK);
    assert_eq!(server.get_stream_ai_enabled("test_s1"), Some(false));

    let res_zone = client
        .post(format!("http://{addr}/api/zone/test_s1"))
        .header("Content-Type", "application/json")
        .body(r#"{"enabled":true,"roi":{"type":"rect","coords":[0.1,0.2,0.8,0.9]}}"#)
        .send()
        .await
        .unwrap();
    assert_eq!(res_zone.status(), reqwest::StatusCode::OK);
    assert_eq!(server.get_stream_ai_enabled("test_s1"), Some(true));

    let res_empty = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[]}"#)
        .send()
        .await
        .unwrap();

    assert_eq!(res_empty.status(), reqwest::StatusCode::OK);
    assert!(server.stream_order().is_empty());
    assert!(!server.has_stream("test_s1"));
}

#[tokio::test]
async fn test_webrtc_offer_query_routing() {
    let detect_wrapper = Arc::new(server::detector::DetectWrapper::new());
    let server = Arc::new(WebRtcServer::new("0.0.0.0:8181", detect_wrapper, vec![]));
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    let srv_clone = Arc::clone(&server);
    tokio::spawn(async move {
        let _ = WebServer::run_with_listener(srv_clone, listener).await;
    });

    let client = reqwest::Client::new();

    let res = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[{"id":"test_cam","url":"rtsp://127.0.0.1:8554/live"}]}"#)
        .send()
        .await
        .unwrap();
    assert_eq!(res.status(), reqwest::StatusCode::OK);

    let res_offer = client
        .post(format!("http://{addr}/offer?src=test_cam"))
        .body("dummy-sdp")
        .send()
        .await
        .unwrap();
    assert_eq!(res_offer.status(), reqwest::StatusCode::INTERNAL_SERVER_ERROR);
    let txt = res_offer.text().await.unwrap();
    assert!(txt.contains("stream=test_cam"));

    let res_webrtc = client
        .post(format!("http://{addr}/api/webrtc?stream=test_cam"))
        .body("dummy-sdp")
        .send()
        .await
        .unwrap();
    assert_eq!(res_webrtc.status(), reqwest::StatusCode::INTERNAL_SERVER_ERROR);
    let txt2 = res_webrtc.text().await.unwrap();
    assert!(txt2.contains("stream=test_cam"));

    let res_404 = client
        .post(format!("http://{addr}/offer?src=nonexistent"))
        .body("dummy-sdp")
        .send()
        .await
        .unwrap();
    assert_eq!(res_404.status(), reqwest::StatusCode::NOT_FOUND);

    let res_rest = client
        .post(format!("http://{addr}/api/webrtc/test_cam"))
        .body("dummy-sdp")
        .send()
        .await
        .unwrap();
    assert_eq!(res_rest.status(), reqwest::StatusCode::INTERNAL_SERVER_ERROR);
    let txt3 = res_rest.text().await.unwrap();
    assert!(txt3.contains("stream=test_cam"));

    let res_legacy = client
        .post(format!("http://{addr}/test_cam"))
        .body("dummy-sdp")
        .send()
        .await
        .unwrap();
    assert_eq!(res_legacy.status(), reqwest::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn test_api_detection() {
    let detect_wrapper = Arc::new(server::detector::DetectWrapper::new());
    let server = Arc::new(WebRtcServer::new("0.0.0.0:8181", detect_wrapper, vec![]));
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    let srv_clone = Arc::clone(&server);
    tokio::spawn(async move {
        let _ = WebServer::run_with_listener(srv_clone, listener).await;
    });

    let client = reqwest::Client::new();

    // 1. POST /api/detection
    let res = client
        .post(format!("http://{addr}/api/detection"))
        .header("Content-Type", "application/json")
        .body(r#"{"target_classes":["smoking","fire"],"rules":[]}"#)
        .send()
        .await
        .unwrap();
    assert_eq!(res.status(), reqwest::StatusCode::OK);

    // 2. GET /api/detection
    let get_res = client
        .get(format!("http://{addr}/api/detection"))
        .send()
        .await
        .unwrap();
    assert_eq!(get_res.status(), reqwest::StatusCode::OK);
    let body_str = get_res.text().await.unwrap();
    let val: serde_json::Value = serde_json::from_str(&body_str).unwrap();
    assert_eq!(val["target_classes"], serde_json::json!(["smoking", "fire"]));
}


