const std = @import("std");

pub fn print_stdout(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch return;
    std.fs.File.stdout().writeAll(msg) catch return;
}

pub fn print_stderr(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch return;
    std.fs.File.stderr().writeAll(msg) catch return;
}

pub fn get_exe_name(arg0: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, arg0, '/')) |idx| {
        return arg0[idx + 1 ..];
    }
    return arg0;
}
