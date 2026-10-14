const std = @import("std");
const base = @import("base");
const hwid = base.hwid;

const cli_print = @import("print.zig");
const print_stdout = cli_print.print_stdout;
const print_stderr = cli_print.print_stderr;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    const id = hwid.get_hardware_id(allocator) catch |err| {
        print_stderr("error: failed to get hardware id ({s})\n", .{@errorName(err)});
        return;
    };
    defer allocator.free(id);

    print_stdout("{s}\n", .{id});
}
