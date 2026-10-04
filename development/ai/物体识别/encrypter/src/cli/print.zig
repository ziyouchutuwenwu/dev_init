const std = @import("std");

pub fn print_stdout(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch return;
    _ = std.c.write(1, msg.ptr, msg.len);
}

pub fn print_stderr(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch return;
    _ = std.c.write(2, msg.ptr, msg.len);
}

pub fn get_exe_name(arg0: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, arg0, '/')) |idx| {
        return arg0[idx + 1 ..];
    }
    return arg0;
}
