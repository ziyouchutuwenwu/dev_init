use std::path::Path;

pub fn resolve_config_path() -> Result<String, Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if let Some(arg) = args.get(1) {
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
