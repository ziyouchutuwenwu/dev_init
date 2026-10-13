use server::config::AppConfig;
use server::prepare::{init_detector, resolve_config_path, start_initial_streams};
use server::web_rtc::WebRtcServer;
use std::sync::Arc;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let _ = env_logger::Builder::from_env(
        env_logger::Env::default().default_filter_or(
            "info,rtc_dtls::handshake=error,rtc::peer_connection::handler=error,rtc=error,quinn_udp=warn,webrtc::peer_connection::driver=warn",
        ),
    )
    .try_init();
    let config_path = resolve_config_path()?;
    server::config::set_global_config_path(&config_path);
    server::updater::init_alert_config_from_config(&config_path);
    let config = AppConfig::load_from_file(&config_path)?;
    let streams = config.input.get_streams();
    if streams.is_empty() {
        return Err("配置文件未包含有效视频流".into());
    }

    let http_addr = config.server.http_addr();
    let listener = match tokio::net::TcpListener::bind(&http_addr).await {
        Ok(l) => l,
        Err(e) => {
            if e.kind() == std::io::ErrorKind::AddrInUse {
                log::error!("端口已被占用");
            } else {
                log::error!("无法监听端口 {}: {e}", http_addr);
            }
            std::process::exit(1);
        }
    };

    let stream_ids: Vec<&str> = streams.iter().map(|s| s.id.as_str()).collect();
    log::info!(
        "启动成功: http://{} (通道: {})",
        http_addr,
        stream_ids.join(", ")
    );

    let detect_wrapper = init_detector(streams.len());
    let initial_streams =
        start_initial_streams(streams, std::sync::Arc::clone(&detect_wrapper)).await?;
    let webrtc_server = Arc::new(WebRtcServer::new(
        &http_addr,
        std::sync::Arc::clone(&detect_wrapper),
        initial_streams,
    ));

    let srv_clone = Arc::clone(&webrtc_server);
    tokio::select! {
        res = srv_clone.run_signaling_server_with_listener(listener) => {
            if let Err(e) = res {
                log::error!("webrtc 服务运行异常: {e}");
            }
        }
        _ = tokio::signal::ctrl_c() => {
            log::info!("接收到退出信号，释放硬件资源并退出");
        }
    }

    webrtc_server.stop_all_streams();
    let _ = detect_wrapper.release_all();
    std::process::exit(0);
}
