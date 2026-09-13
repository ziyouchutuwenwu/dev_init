pub mod config;
pub mod detector;
pub mod on_detected;
pub mod prepare;
pub mod rtsp2frame;
pub mod web_rtc;

use config::AppConfig;
use prepare::{init_detector, resolve_config_path, start_all_streams, start_webrtc_server};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let _ = env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).try_init();

    let config_path = resolve_config_path()?;
    println!("==========================================================");
    println!("[server] 正在加载配置文件: {}", config_path);
    let config = AppConfig::load_from_file(&config_path)?;
    let streams = config.input.get_streams();
    if streams.is_empty() {
        return Err("配置文件未包含有效视频流".into());
    }

    let http_addr = config.server.http_addr();
    println!("[server] 配置就绪: HTTP/信令端口 = {}, 视频流数量 = {}", http_addr, streams.len());
    for s in &streams {
        println!("  • 通道 [{}] -> RTSP源: {}", s.id, s.input);
    }
    println!("==========================================================");

    let detect_wrapper = init_detector(streams.len());
    let modbus_rules = match &config.trigger {
        Some(t) => Some(t.modbus.clone()),
        None => None,
    };

    let (stream_contexts, _streamer_handles) =
        start_all_streams(streams, detect_wrapper, modbus_rules).await?;

    start_webrtc_server(&http_addr, stream_contexts).await
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::web_rtc::{SignalingServer, StreamContext, WebRtcServer};
    use std::sync::Arc;

    #[test]
    fn test_config_parsing() {
        let cfg = AppConfig::load_from_file("../config.yaml").expect("load config failed");
        println!("Parsed config: {:?}", cfg);
        assert_eq!(cfg.server.host, "0.0.0.0");
        assert_eq!(cfg.server.port, 8181);
        let streams = cfg.input.get_streams();
        println!("Streams: {:?}", streams);
        assert_eq!(streams.len(), 2);
        assert_eq!(streams[0].id, "aaa");
        assert_eq!(streams[1].id, "bbb");
    }

    #[test]
    fn test_resolve_stream_id() {
        let ctx_aaa = StreamContext {
            stream_id: "aaa".to_string(),
            input_url: "rtsp://127.0.0.1/1".to_string(),
            video_track: WebRtcServer::create_video_track("aaa"),
            tx_detection: tokio::sync::broadcast::channel(16).0,
            latest_detection: Arc::new(tokio::sync::RwLock::new(None)),
        };
        let ctx_bbb = StreamContext {
            stream_id: "bbb".to_string(),
            input_url: "rtsp://127.0.0.1/2".to_string(),
            video_track: WebRtcServer::create_video_track("bbb"),
            tx_detection: tokio::sync::broadcast::channel(16).0,
            latest_detection: Arc::new(tokio::sync::RwLock::new(None)),
        };
        let server = WebRtcServer::new("0.0.0.0:8181", vec![ctx_aaa, ctx_bbb]);
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/aaa"), Some("aaa".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/bbb"), Some("bbb".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/"), Some("aaa".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/offer"), Some("aaa".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/offer/aaa"), Some("aaa".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/offer/bbb"), Some("bbb".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/?stream=bbb"), Some("bbb".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/?id=aaa"), Some("aaa".to_string()));
        assert_eq!(SignalingServer::resolve_stream_id(&server, "/custom"), Some("custom".to_string()));
    }

    #[tokio::test]
    async fn test_webrtc_offer_and_answer() {
        use webrtc::api::media_engine::MediaEngine;
        use webrtc::api::APIBuilder;
        use webrtc::peer_connection::configuration::RTCConfiguration;

        let ctx_aaa = StreamContext {
            stream_id: "aaa".to_string(),
            input_url: "rtsp://127.0.0.1/1".to_string(),
            video_track: WebRtcServer::create_video_track("aaa"),
            tx_detection: tokio::sync::broadcast::channel(16).0,
            latest_detection: Arc::new(tokio::sync::RwLock::new(None)),
        };
        let server = Arc::new(WebRtcServer::new("0.0.0.0:8181", vec![ctx_aaa]));

        let mut m = MediaEngine::default();
        m.register_default_codecs().unwrap();
        let api = APIBuilder::new().with_media_engine(m).build();
        let client_pc = api.new_peer_connection(RTCConfiguration::default()).await.unwrap();
        client_pc.add_transceiver_from_kind(webrtc::rtp_transceiver::rtp_codec::RTPCodecType::Video, None).await.unwrap();
        let _dc = client_pc.create_data_channel("detection", None).await.unwrap();

        let offer = client_pc.create_offer(None).await.unwrap();
        client_pc.set_local_description(offer.clone()).await.unwrap();

        let answer_sdp = server.handle_offer("aaa", &offer.sdp).await;
        match &answer_sdp {
            Ok(ans) => println!("Server Answer SDP:\n{}", ans),
            Err(e) => println!("Server handle_offer error: {}", e),
        }
        assert!(answer_sdp.is_ok());
    }

    #[tokio::test]
    async fn test_signaling_full_http() {
        use tokio::net::TcpStream;
        use tokio::io::{AsyncWriteExt, AsyncReadExt};

        let ctx_aaa = StreamContext {
            stream_id: "aaa".to_string(),
            input_url: "rtsp://127.0.0.1/1".to_string(),
            video_track: WebRtcServer::create_video_track("aaa"),
            tx_detection: tokio::sync::broadcast::channel(16).0,
            latest_detection: Arc::new(tokio::sync::RwLock::new(None)),
        };
        let server = Arc::new(WebRtcServer::new("127.0.0.1:18181", vec![ctx_aaa]));
        let srv = Arc::clone(&server);
        tokio::spawn(async move {
            let _ = srv.run_signaling_server().await;
        });

        tokio::time::sleep(std::time::Duration::from_millis(50)).await;

        let mut stream = TcpStream::connect("127.0.0.1:18181").await.unwrap();
        let options_req = "OPTIONS /aaa HTTP/1.1\r\nHost: 127.0.0.1:18181\r\nAccess-Control-Request-Method: POST\r\nAccess-Control-Request-Headers: content-type\r\nOrigin: http://localhost:4000\r\n\r\n";
        stream.write_all(options_req.as_bytes()).await.unwrap();
        let mut resp = vec![0u8; 1024];
        let n = stream.read(&mut resp).await.unwrap();
        let resp_str = String::from_utf8_lossy(&resp[..n]);
        println!("OPTIONS response:\n{}", resp_str);
        assert!(resp_str.starts_with("HTTP/1.1 204 No Content"));
        assert!(resp_str.contains("Access-Control-Allow-Origin: *"));
        assert!(resp_str.contains("Access-Control-Allow-Headers: Content-Type"));

        let mut stream = TcpStream::connect("127.0.0.1:18181").await.unwrap();
        let health_req = "GET /health HTTP/1.1\r\nHost: 127.0.0.1:18181\r\n\r\n";
        stream.write_all(health_req.as_bytes()).await.unwrap();
        let mut resp = vec![0u8; 1024];
        let n = stream.read(&mut resp).await.unwrap();
        let resp_str = String::from_utf8_lossy(&resp[..n]);
        assert!(resp_str.starts_with("HTTP/1.1 200 OK"));
        assert!(resp_str.ends_with("ok"));

        use webrtc::api::media_engine::MediaEngine;
        use webrtc::api::APIBuilder;
        use webrtc::peer_connection::configuration::RTCConfiguration;
        let mut m = MediaEngine::default();
        m.register_default_codecs().unwrap();
        let api = APIBuilder::new().with_media_engine(m).build();
        let client_pc = api.new_peer_connection(RTCConfiguration::default()).await.unwrap();
        client_pc.add_transceiver_from_kind(webrtc::rtp_transceiver::rtp_codec::RTPCodecType::Video, None).await.unwrap();
        let mut client_gather = client_pc.gathering_complete_promise().await;
        let offer = client_pc.create_offer(None).await.unwrap();
        client_pc.set_local_description(offer.clone()).await.unwrap();
        let _ = tokio::time::timeout(std::time::Duration::from_millis(1500), client_gather.recv()).await;
        let sdp = offer.sdp;

        let mut stream = TcpStream::connect("127.0.0.1:18181").await.unwrap();
        let post_req = format!(
            "POST /aaa HTTP/1.1\r\nHost: 127.0.0.1:18181\r\nUser-Agent: Mozilla/5.0\r\nContent-Type: text/plain;charset=UTF-8\r\nContent-Length: {}\r\nOrigin: http://localhost:4000\r\n\r\n{}",
            sdp.len(),
            sdp
        );
        stream.write_all(post_req.as_bytes()).await.unwrap();
        let mut resp = vec![0u8; 4096];
        let n = stream.read(&mut resp).await.unwrap();
        let resp_str = String::from_utf8_lossy(&resp[..n]);
        println!("POST response (first {} bytes):\n{}", n, &resp_str[..resp_str.len().min(300)]);
        assert!(resp_str.starts_with("HTTP/1.1 200 OK"));
        assert!(resp_str.contains("Access-Control-Allow-Origin: *"));
        assert!(resp_str.contains("Content-Type: application/sdp"));

        let header_end_pos = resp_str.find("\r\n\r\n").unwrap() + 4;
        let answer_sdp = &resp_str[header_end_pos..];
        let answer_desc = webrtc::peer_connection::sdp::session_description::RTCSessionDescription::answer(answer_sdp.to_string()).unwrap();
        client_pc.set_remote_description(answer_desc).await.unwrap();
    }
}
