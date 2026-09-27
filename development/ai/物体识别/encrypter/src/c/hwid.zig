const std = @import("std");
const base = @import("base");
const hwid = base.hwid;

const c_allocator = std.heap.c_allocator;

export fn get_hwid(out_buf: ?[*]u8, max_len: usize) c_int {
    const buf = out_buf orelse return -1;
    const id = hwid.get_hardware_id(c_allocator) catch return -2;
    defer c_allocator.free(id);

    if (id.len >= max_len) return -3;

    @memcpy(buf[0..id.len], id);
    buf[id.len] = 0;
    return @as(c_int, @intCast(id.len));
}
