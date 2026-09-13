use crate::config::base::ConfigSection;
use crate::config::trigger::ModbusRule;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq)]
pub struct TriggerConfig {
    #[serde(default)]
    pub modbus: HashMap<String, ModbusRule>,
}

impl TriggerConfig {
    pub fn from_section(section: Option<&ConfigSection>) -> Option<Self> {
        let sec = section?;
        let modbus_sec = sec.get_child("modbus")?;

        let mut modbus = HashMap::new();
        for (target_name, target_sec) in modbus_sec.children() {
            modbus.insert(
                target_name.clone(),
                ModbusRule::from_section(target_sec),
            );
        }

        if modbus.is_empty() {
            None
        } else {
            Some(Self { modbus })
        }
    }
}
