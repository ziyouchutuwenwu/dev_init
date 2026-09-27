const std = @import("std");

const raw_labels = @embedFile("resources/coco_80_labels_list.txt");

fn make_buf() [raw_labels.len + 1]u8 {
    @setEvalBranchQuota(200000);
    var buf: [raw_labels.len + 1]u8 = undefined;
    for (raw_labels, 0..) |c, i| {
        if (c == '\r' or c == '\n') {
            buf[i] = 0;
        } else {
            buf[i] = c;
        }
    }
    buf[raw_labels.len] = 0;
    return buf;
}

const static_buf = make_buf();

fn count_items() usize {
    @setEvalBranchQuota(200000);
    var count: usize = 0;
    var in_word = false;
    for (static_buf) |c| {
        if (c != 0) {
            if (!in_word) {
                count += 1;
                in_word = true;
            }
        } else {
            in_word = false;
        }
    }
    return count;
}

const TOTAL = count_items();

fn make_offsets() [TOTAL]usize {
    @setEvalBranchQuota(200000);
    var offs: [TOTAL]usize = undefined;
    var count: usize = 0;
    var in_word = false;
    for (static_buf, 0..) |c, i| {
        if (c != 0) {
            if (!in_word) {
                offs[count] = i;
                count += 1;
                in_word = true;
            }
        } else {
            in_word = false;
        }
    }
    return offs;
}

const static_offsets = make_offsets();

fn make_ptrs() [TOTAL + 1]?[*:0]const u8 {
    @setEvalBranchQuota(200000);
    var ptrs: [TOTAL + 1]?[*:0]const u8 = undefined;
    for (static_offsets, 0..) |offset, i| {
        ptrs[i] = @ptrCast(&static_buf[offset]);
    }
    ptrs[TOTAL] = null;
    return ptrs;
}

const static_ptrs = make_ptrs();

export fn get_labels_list() [*]const ?[*:0]const u8 {
    return &static_ptrs;
}
