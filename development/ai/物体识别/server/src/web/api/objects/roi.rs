use crate::config::objects::roi::RoiConfig;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

#[derive(Debug, Clone, PartialEq)]
pub enum RoiObject {
    Rect([f64; 4]),
    Polygon(Vec<[f64; 2]>),
}

impl Serialize for RoiObject {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        #[derive(Serialize)]
        #[serde(tag = "type", content = "coords")]
        enum Tagged<'a> {
            #[serde(rename = "rect")]
            Rect(&'a [f64; 4]),
            #[serde(rename = "polygon")]
            Polygon(&'a [[f64; 2]]),
        }

        match self {
            RoiObject::Rect(r) => Tagged::Rect(r).serialize(serializer),
            RoiObject::Polygon(p) => Tagged::Polygon(p).serialize(serializer),
        }
    }
}

impl<'de> Deserialize<'de> for RoiObject {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        #[serde(tag = "type", content = "coords")]
        enum Tagged {
            #[serde(rename = "rect")]
            Rect([f64; 4]),
            #[serde(rename = "polygon")]
            Polygon(Vec<[f64; 2]>),
        }

        #[derive(Deserialize)]
        #[serde(untagged)]
        enum Helper {
            Tagged(Tagged),
            Rect([f64; 4]),
            Polygon(Vec<[f64; 2]>),
            Str(String),
        }

        match Helper::deserialize(deserializer)? {
            Helper::Tagged(Tagged::Rect(r)) | Helper::Rect(r) => Ok(RoiObject::Rect(r)),
            Helper::Tagged(Tagged::Polygon(p)) | Helper::Polygon(p) => Ok(RoiObject::Polygon(p)),
            Helper::Str(s) => {
                if let Ok(rect) = serde_json::from_str::<[f64; 4]>(&s) {
                    Ok(RoiObject::Rect(rect))
                } else if let Ok(poly) = serde_json::from_str::<Vec<[f64; 2]>>(&s) {
                    Ok(RoiObject::Polygon(poly))
                } else if let Ok(tagged) = serde_json::from_str::<Tagged>(&s) {
                    match tagged {
                        Tagged::Rect(r) => Ok(RoiObject::Rect(r)),
                        Tagged::Polygon(p) => Ok(RoiObject::Polygon(p)),
                    }
                } else {
                    Err(serde::de::Error::custom(format!("invalid roi format: {s}")))
                }
            }
        }
    }
}

impl From<RoiConfig> for RoiObject {
    fn from(cfg: RoiConfig) -> Self {
        match cfg {
            RoiConfig::Rect(r) => RoiObject::Rect(r),
            RoiConfig::Polygon(p) => RoiObject::Polygon(p),
        }
    }
}

impl TryFrom<RoiObject> for RoiConfig {
    type Error = &'static str;

    fn try_from(obj: RoiObject) -> Result<Self, Self::Error> {
        match obj {
            RoiObject::Rect(r) => Ok(RoiConfig::Rect(r)),
            RoiObject::Polygon(p) => {
                if p.len() < 3 {
                    Err("多边形 ROI 至少需要 3 个顶点坐标")
                } else {
                    Ok(RoiConfig::Polygon(p))
                }
            }
        }
    }
}
