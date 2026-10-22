use geo::{Contains, Coord, LineString, Point, Polygon, Rect};
pub use crate::config::objects::roi::RoiConfig;

pub fn contains_point(roi: &RoiConfig, p: [f64; 2]) -> bool {
    let pt = Point::new(p[0], p[1]);
    match roi {
        RoiConfig::Rect(r) => {
            let rect = Rect::new(
                Coord { x: r[0].min(r[2]), y: r[1].min(r[3]) },
                Coord { x: r[0].max(r[2]), y: r[1].max(r[3]) },
            );
            p[0] >= rect.min().x && p[0] <= rect.max().x
                && p[1] >= rect.min().y && p[1] <= rect.max().y
        }
        RoiConfig::Polygon(poly) => {
            if poly.len() < 3 {
                return false;
            }
            let coords: Vec<Coord<f64>> = poly.iter().map(|pt| Coord { x: pt[0], y: pt[1] }).collect();
            let exterior = LineString::new(coords);
            let polygon = Polygon::new(exterior, vec![]);
            polygon.contains(&pt)
        }
    }
}

impl RoiConfig {
    pub fn contains_point(&self, p: [f64; 2]) -> bool {
        contains_point(self, p)
    }
}
