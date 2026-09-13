use server::config::AppConfig;
use server::prepare::{init_detector, resolve_config_path, start_all_streams, start_webrtc_server_with_listener};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut builder = pretty_env_logger::formatted_builder();
    if let Ok(s) = std::env::var("RUST_LOG") {
        builder.parse_filters(&s);
    } else {
        builder.filter_level(log::LevelFilter::Info);
    }
    let _ = builder.try_init();

    let config_path = resolve_config_path()?;
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
    let modbus_rules = match &config.trigger {
        Some(t) => Some(t.modbus.clone()),
        None => None,
    };

    let (stream_contexts, _streamer_handles) =
        start_all_streams(streams, detect_wrapper, modbus_rules).await?;

    start_webrtc_server_with_listener(&http_addr, stream_contexts, listener).await
}
