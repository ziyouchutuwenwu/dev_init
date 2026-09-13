use crate::config::ModbusRule;
use crate::detector::detection_result::DetectionResult;
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::broadcast;

pub struct ModbusHandler;

impl ModbusHandler {
    pub fn start(
        stream_id: impl Into<String>,
        receiver: broadcast::Receiver<Arc<DetectionResult>>,
        rules: Option<HashMap<String, ModbusRule>>,
    ) {
        tokio::spawn(loop_check(stream_id.into(), receiver, rules));
    }
}

async fn loop_check(
    stream_id: String,
    mut receiver: broadcast::Receiver<Arc<DetectionResult>>,
    rules: Option<HashMap<String, ModbusRule>>,
) {
    println!("[on_detected:modbus:{stream_id}] 订阅协程已启动，等待检测目标事件...");

    let mut last_alarm_times: HashMap<String, Instant> = HashMap::new();

    loop {
        match receiver.recv().await {
            Ok(result) => {
                for detection in &result.detections {
                    let label = match detection.get("label") {
                        Some(serde_json::Value::String(s)) => s.clone(),
                        _ => continue,
                    };

                    let confidence = match detection.get("confidence") {
                        Some(serde_json::Value::Number(n)) => match n.as_f64() {
                            Some(v) => v,
                            None => 0.0,
                        },
                        _ => 0.0,
                    };

                    let (coil, frozon_duration, min_confidence) = match &rules {
                        Some(map) => match map.get(&label) {
                            Some(rule) => (
                                rule.coil,
                                Duration::from_secs(rule.frozon_duration),
                                rule.min_confidence,
                            ),
                            None => continue,
                        },
                        None => (0, Duration::from_secs(3), 0.5),
                    };

                    if confidence < min_confidence {
                        continue;
                    }

                    let should_alarm = match last_alarm_times.get(&label) {
                        Some(time) => time.elapsed() >= frozon_duration,
                        None => true,
                    };

                    if should_alarm {
                        last_alarm_times.insert(label.clone(), Instant::now());
                        println!(
                            "[on_detected:modbus:{stream_id}] ⚡ 触发 Modbus 信号! 类型: {label}, 线圈(coil): {coil}, 置信度: {confidence:.2}"
                        );
                    }
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => {}
            Err(broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }

    println!("[on_detected:modbus:{stream_id}] 订阅协程已退出");
}
