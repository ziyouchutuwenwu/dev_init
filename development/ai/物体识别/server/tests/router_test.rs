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

    // 初始状态应该没有流
    assert!(server.stream_order().is_empty());

    // 模拟调用 post_streams 热更新流配置（使用不存在的测试 URL，验证内存流的增删状态）
    let res = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[{"id":"test_s1","url":"rtsp://127.0.0.1:8554/live1"}]}"#)
        .send()
        .await
        .unwrap();

    assert_eq!(res.status(), reqwest::StatusCode::OK);
    // 检查 server 内存中的 stream_order 是否已更新
    assert_eq!(server.stream_order(), vec!["test_s1"]);
    assert!(server.has_stream("test_s1"));

    // 模拟再次更新，清空流
    let res_empty = client
        .post(format!("http://{addr}/api/streams"))
        .header("Content-Type", "application/json")
        .body(r#"{"streams":[{"id":"test_s2","url":"rtsp://127.0.0.1:8554/live2"}]}"#)
        .send()
        .await
        .unwrap();

    assert_eq!(res_empty.status(), reqwest::StatusCode::OK);
    assert_eq!(server.stream_order(), vec!["test_s2"]);
    assert!(!server.has_stream("test_s1"));
    assert!(server.has_stream("test_s2"));
}

