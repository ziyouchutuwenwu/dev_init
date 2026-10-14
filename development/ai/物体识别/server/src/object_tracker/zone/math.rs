use geo::{Coord, Intersects, Line};

pub fn segments_intersect(a: [f64; 2], b: [f64; 2], c: [f64; 2], d: [f64; 2]) -> bool {
    let line1 = Line::new(Coord { x: a[0], y: a[1] }, Coord { x: b[0], y: b[1] });
    let line2 = Line::new(Coord { x: c[0], y: c[1] }, Coord { x: d[0], y: d[1] });
    line1.intersects(&line2)
}

pub fn compute_crossing_direction(
    prev: [f64; 2],
    curr: [f64; 2],
    line_p1: [f64; 2],
    line_p2: [f64; 2],
) -> f64 {
    let line_dx = line_p2[0] - line_p1[0];
    let line_dy = line_p2[1] - line_p1[1];
    let move_dx = curr[0] - prev[0];
    let move_dy = curr[1] - prev[1];

    line_dx * move_dy - line_dy * move_dx
}
