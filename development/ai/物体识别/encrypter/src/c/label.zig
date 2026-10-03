const std = @import("std");
const consts = @import("label_consts.zig");

fn LabelTable(comptime raw_content: []const u8) type {
    return struct {
        fn make_buf() [raw_content.len + 1]u8 {
            @setEvalBranchQuota(200000);
            var b: [raw_content.len + 1]u8 = undefined;
            for (raw_content, 0..) |c, i| {
                if (c == '\r' or c == '\n') {
                    b[i] = 0;
                } else {
                    b[i] = c;
                }
            }
            b[raw_content.len] = 0;
            return b;
        }

        const buf = make_buf();

        fn count_items() usize {
            @setEvalBranchQuota(200000);
            var count: usize = 0;
            var in_word = false;
            for (buf) |c| {
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

        const total = count_items();

        fn make_offsets() [total]usize {
            @setEvalBranchQuota(200000);
            var offs: [total]usize = undefined;
            var count: usize = 0;
            var in_word = false;
            for (buf, 0..) |c, i| {
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

        const offsets = make_offsets();

        fn make_ptrs() [total + 1]?[*:0]const u8 {
            @setEvalBranchQuota(200000);
            var p: [total + 1]?[*:0]const u8 = undefined;
            for (offsets, 0..) |offset, i| {
                p[i] = @ptrCast(&buf[offset]);
            }
            p[total] = null;
            return p;
        }

        pub const ptrs = make_ptrs();
    };
}

const Entry = struct {
    name: []const u8,
    ptrs: [*]const ?[*:0]const u8,
};

fn make_entries() [consts.model_label_map.len]Entry {
    @setEvalBranchQuota(500000);
    var list: [consts.model_label_map.len]Entry = undefined;
    inline for (consts.model_label_map, 0..) |item, i| {
        const Table = LabelTable(item[1]);
        list[i] = .{
            .name = item[0],
            .ptrs = &Table.ptrs,
        };
    }
    return list;
}

const entries = make_entries();

export fn get_model_labels_list(model_id: ?[*:0]const u8) [*]const ?[*:0]const u8 {
    if (model_id) |mid| {
        const id_slice = std.mem.sliceTo(mid, 0);
        for (entries) |entry| {
            if (std.mem.eql(u8, id_slice, entry.name)) {
                return entry.ptrs;
            }
        }
    }
    return entries[0].ptrs;
}

export fn get_labels_list() [*]const ?[*:0]const u8 {
    return get_model_labels_list(null);
}
