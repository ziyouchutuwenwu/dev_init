pub fn ccw(p: [f64; 2], q: [f64; 2], r: [f64; 2]) -> f64 {
    (r[1] - p[1]) * (q[0] - p[0]) - (r[0] - p[0]) * (q[1] - p[1])
}

pub fn segments_intersect(a: [f64; 2], b: [f64; 2], c: [f64; 2], d: [f64; 2]) -> bool {
    let ccw_abc = ccw(a, b, c);
    let ccw_abd = ccw(a, b, d);
    let ccw_cda = ccw(c, d, a);
    let ccw_cdb = ccw(c, d, b);

    if ((ccw_abc > 0.0 && ccw_abd < 0.0) || (ccw_abc < 0.0 && ccw_abd > 0.0))
        && ((ccw_cda > 0.0 && ccw_cdb < 0.0) || (ccw_cda < 0.0 && ccw_cdb > 0.0))
    {
        return true;
    }

    if ccw_abc.abs() < 1e-9 && is_on_segment(c, a, b) {
        return true;
    }
    if ccw_abd.abs() < 1e-9 && is_on_segment(d, a, b) {
        return true;
    }
    if ccw_cda.abs() < 1e-9 && is_on_segment(a, c, d) {
        return true;
    }
    if ccw_cdb.abs() < 1e-9 && is_on_segment(b, c, d) {
        return true;
    }

    false
}

pub fn is_on_segment(p: [f64; 2], a: [f64; 2], b: [f64; 2]) -> bool {
    p[0] >= a[0].min(b[0]) - 1e-9
        && p[0] <= a[0].max(b[0]) + 1e-9
        && p[1] >= a[1].min(b[1]) - 1e-9
        && p[1] <= a[1].max(b[1]) + 1e-9
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
