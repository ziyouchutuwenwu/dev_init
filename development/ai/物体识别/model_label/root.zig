const std = @import("std");
const label = @import("src/c/label.zig");

comptime {
    _ = label;
}

test "model labels and comments" {
    const ind_labels = label.get_model_labels_list("industry");
    try std.testing.expect(ind_labels != null);
    const first_ind = std.mem.sliceTo(ind_labels.?[0].?, 0);
    try std.testing.expectEqualStrings("person", first_ind);

    const ind_desc = label.get_model_desc("industry");
    try std.testing.expect(ind_desc != null);
    try std.testing.expectEqualStrings("", std.mem.sliceTo(ind_desc.?, 0));

    const anf_labels = label.get_model_labels_list("anfang");
    try std.testing.expect(anf_labels != null);
    const first_anf = std.mem.sliceTo(anf_labels.?[0].?, 0);
    try std.testing.expectEqualStrings("helmet", first_anf);

    const anf_desc = label.get_model_desc("anfang");
    try std.testing.expect(anf_desc != null);
    try std.testing.expectEqualStrings("", std.mem.sliceTo(anf_desc.?, 0));
}
