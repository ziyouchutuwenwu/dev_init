const std = @import("std");
const base = @import("base");
const hwid = base.hwid;

const print_stdout = @import("print.zig").print_stdout;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    const id = try hwid.get_hardware_id(allocator);
    defer allocator.free(id);

    print_stdout("{s}\n", .{id});
}
