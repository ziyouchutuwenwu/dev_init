use std::path::Path;

pub fn resolve_config_path() -> Result<String, Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if let Some(arg) = args.get(1) {
        if arg == "-h" || arg == "--help" {
            println!("==========================================================");
            println!("  rtsp webrtc npu 检测服务");
            println!("==========================================================");
            println!("用法:");
            println!("  ./server [config.yaml]");
            println!("  ./start.sh [config.yaml]");
            println!("==========================================================");
            std::process::exit(0);
        }
        return Ok(arg.clone());
    }
    if Path::new("config.yaml").exists() {
        return Ok("config.yaml".to_string());
    }
    if Path::new("config.yml").exists() {
        return Ok("config.yml".to_string());
    }
    if Path::new("../config.yaml").exists() {
        return Ok("../config.yaml".to_string());
    }
    if Path::new("../config.yml").exists() {
        return Ok("../config.yml".to_string());
    }
    Err("未找到配置文件 config.yaml".into())
}
