use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "coords")]
pub enum RoiConfig {
    #[serde(rename = "rect")]
    Rect([f64; 4]),
    #[serde(rename = "polygon")]
    Polygon(Vec<[f64; 2]>),
}

impl RoiConfig {
    pub fn contains_point(&self, p: [f64; 2]) -> bool {
        match self {
            RoiConfig::Rect(r) => {
                let x_min = r[0].min(r[2]);
                let x_max = r[0].max(r[2]);
                let y_min = r[1].min(r[3]);
                let y_max = r[1].max(r[3]);
                p[0] >= x_min && p[0] <= x_max && p[1] >= y_min && p[1] <= y_max
            }
            RoiConfig::Polygon(poly) => {
                if poly.len() < 3 {
                    return true;
                }
                let mut inside = false;
                let n = poly.len();
                let px = p[0];
                let py = p[1];

                let mut j = n - 1;
                for i in 0..n {
                    let xi = poly[i][0];
                    let yi = poly[i][1];
                    let xj = poly[j][0];
                    let yj = poly[j][1];

                    let intersect = ((yi > py) != (yj > py))
                        && (px < (xj - xi) * (py - yi) / (yj - yi + 1e-12) + xi);
                    if intersect {
                        inside = !inside;
                    }
                    j = i;
                }
                inside
            }
        }
    }
}
