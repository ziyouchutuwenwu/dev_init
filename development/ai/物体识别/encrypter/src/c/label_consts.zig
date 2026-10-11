pub const model_label_map = .{
    .{ "yolo_raw", @embedFile("resources/coco_80_labels_list.txt") },
    .{ "yolo_all", @embedFile("resources/coco_80_labels_list.txt") },
    .{ "aaa", @embedFile("resources/coco_80_labels_list.txt") },
    .{ "quexian", @embedFile("resources/labels_welding_defect.txt") },
};
