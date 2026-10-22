use server::prepare::{init_detector, start_initial_streams};
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
    let config_path = server::config::get_config_path();
    server::updater::init_alert_config_from_config(&config_path);
    let streams = server::config::input::load_config();
    let server_cfg = server::config::server::load_config();
    let http_addr = format!("{}:{}", server_cfg.host, server_cfg.port);
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
    if streams.is_empty() {
        log::info!("配置文件暂无初始视频流，等待通过 web 端或 api 动态添加: http://{}", http_addr);
    } else {
        log::info!(
            "启动成功: http://{} (通道: {})",
            http_addr,
            stream_ids.join(", ")
        );
    }

    let detect_wrapper = init_detector(streams.len());
    let initial_streams =
        start_initial_streams(streams, std::sync::Arc::clone(&detect_wrapper)).await?;
    let webrtc_server = Arc::new(WebRtcServer::new(
        &http_addr,
        std::sync::Arc::clone(&detect_wrapper),
        initial_streams,
    ));

    let srv_clone = Arc::clone(&webrtc_server);
    #[cfg(unix)]
    let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).ok();

    tokio::select! {
        res = srv_clone.run_signaling_server_with_listener(listener) => {
            if let Err(e) = res {
                log::error!("webrtc 服务运行异常: {e}");
            }
        }
        _ = tokio::signal::ctrl_c() => {
            log::info!("接收到退出信号，释放硬件资源并退出");
        }
        _ = async {
            #[cfg(unix)]
            if let Some(s) = &mut sigterm {
                s.recv().await;
                return;
            }
            std::future::pending::<()>().await;
        } => {
            log::info!("接收到 sigterm 信号，释放硬件资源并退出");
        }
    }

    webrtc_server.stop_all_streams();
    let _ = detect_wrapper.release_all();
    std::process::exit(0);
}
