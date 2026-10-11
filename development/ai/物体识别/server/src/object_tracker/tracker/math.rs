pub fn calculate_iou(box_a: &[f64; 4], box_b: &[f64; 4]) -> f64 {
    let x_left = box_a[0].max(box_b[0]);
    let y_top = box_a[1].max(box_b[1]);
    let x_right = box_a[2].min(box_b[2]);
    let y_bottom = box_a[3].min(box_b[3]);

    if x_right <= x_left || y_bottom <= y_top {
        return 0.0;
    }

    let intersection_area = (x_right - x_left) * (y_bottom - y_top);
    let area_a = (box_a[2] - box_a[0]) * (box_a[3] - box_a[1]);
    let area_b = (box_b[2] - box_b[0]) * (box_b[3] - box_b[1]);
    let union_area = area_a + area_b - intersection_area;

    if union_area <= 0.0 {
        0.0
    } else {
        (intersection_area / union_area).clamp(0.0, 1.0)
    }
}

pub fn euclidean_dist(p1: &[f64; 2], p2: &[f64; 2]) -> f64 {
    let dx = p1[0] - p2[0];
    let dy = p1[1] - p2[1];
    (dx * dx + dy * dy).sqrt()
}
