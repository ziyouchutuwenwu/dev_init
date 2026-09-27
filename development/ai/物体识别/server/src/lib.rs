pub mod config;
pub mod detector;
pub mod on_detected;
pub mod prepare;
pub mod rtsp2frame;
pub mod web_rtc;

pub fn current_time_millis() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}
