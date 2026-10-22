pub const model_label_map = .{
    .{ "industry", @embedFile("../../resources/industry.txt") },
    .{ "safety_ppe", @embedFile("../../resources/safety_ppe.txt") },
    .{ "forklift_collision", @embedFile("../../resources/forklift.txt") },
    .{ "steel_defect", @embedFile("../../resources/steel_defect.txt") },
    .{ "tile_defect", @embedFile("../../resources/tile_defect.txt") },
    .{ "yolo_raw", @embedFile("../../resources/coco_80_labels_list.txt") },
    .{ "license_plate", @embedFile("../../resources/license_plate.txt") },
    .{ "lprnet", @embedFile("../../resources/lprnet.txt") },
};
