pub fn calculate_iou(box_a: &[f64; 4], box_b: &[f64; 4]) -> f64 {
    let ax1 = box_a[0].min(box_a[2]);
    let ay1 = box_a[1].min(box_a[3]);
    let ax2 = box_a[0].max(box_a[2]);
    let ay2 = box_a[1].max(box_a[3]);

    let bx1 = box_b[0].min(box_b[2]);
    let by1 = box_b[1].min(box_b[3]);
    let bx2 = box_b[0].max(box_b[2]);
    let by2 = box_b[1].max(box_b[3]);

    let x_left = ax1.max(bx1);
    let y_top = ay1.max(by1);
    let x_right = ax2.min(bx2);
    let y_bottom = ay2.min(by2);

    if x_right <= x_left || y_bottom <= y_top {
        return 0.0;
    }

    let intersection_area = (x_right - x_left) * (y_bottom - y_top);
    let area_a = (ax2 - ax1) * (ay2 - ay1);
    let area_b = (bx2 - bx1) * (by2 - by1);
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
