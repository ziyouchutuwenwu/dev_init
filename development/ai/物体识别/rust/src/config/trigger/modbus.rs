use crate::config::base::ConfigSection;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ModbusRule {
    pub coil: u16,
    pub frozon_duration: u64,
    pub min_confidence: f64,
}

impl ModbusRule {
    pub fn from_section(section: &ConfigSection) -> Self {
        let coil = section.get_u16("coil").unwrap_or(0);
        let frozon_duration = section.get_u64("frozon_duration").unwrap_or(3);
        let min_confidence = section.get_f64("min_confidence").unwrap_or(0.5);

        Self {
            coil,
            frozon_duration,
            min_confidence,
        }
    }
}
