const std = @import("std");
const base = @import("base");
const crypto = base.crypto;
const model = base.model;

const cli_print = @import("print.zig");
const print_stdout = cli_print.print_stdout;
const print_stderr = cli_print.print_stderr;
const get_exe_name = cli_print.get_exe_name;

fn print_usage(exe: []const u8) void {
    print_stdout("usage: {s} --in <model.rknn> [--out <model.enc>] [--id <model_id>]\n", .{exe});
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var args_buf: [32][]const u8 = undefined;
    var args_len: usize = 0;
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();
    while (it.next()) |arg| {
        if (args_len < args_buf.len) {
            args_buf[args_len] = arg;
            args_len += 1;
        }
    }
    const args = args_buf[0..args_len];
    const exe = if (args.len > 0) get_exe_name(args[0]) else "model_tool";

    if (args.len < 2) {
        print_usage(exe);
        return;
    }

    var in_path: ?[]const u8 = null;
    var out_path: ?[]const u8 = null;
    var id_str: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if ((std.mem.eql(u8, args[i], "--in") or std.mem.eql(u8, args[i], "-i")) and i + 1 < args.len) {
            in_path = args[i + 1];
            i += 1;
        } else if ((std.mem.eql(u8, args[i], "--out") or std.mem.eql(u8, args[i], "-o")) and i + 1 < args.len) {
            out_path = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, args[i], "--id") and i + 1 < args.len) {
            id_str = args[i + 1];
            i += 1;
        } else if (!std.mem.startsWith(u8, args[i], "-")) {
            if (in_path == null) {
                in_path = args[i];
            } else if (out_path == null) {
                out_path = args[i];
            }
        }
    }

    const valid_in = in_path orelse {
        print_stderr("error: --in is required\n", .{});
        print_usage(exe);
        return;
    };

    var auto_out_buf: [1024]u8 = undefined;
    const valid_out = out_path orelse blk: {
        if (std.mem.endsWith(u8, valid_in, ".rknn")) {
            break :blk std.fmt.bufPrint(&auto_out_buf, "{s}.enc", .{valid_in[0 .. valid_in.len - 5]}) catch "model.enc";
        }
        break :blk std.fmt.bufPrint(&auto_out_buf, "{s}.enc", .{valid_in}) catch "model.enc";
    };

    const mid = model.encrypt_model(allocator, valid_in, valid_out, crypto.DEFAULT_MODEL_KEY, id_str) catch |err| {
        print_stderr("error: failed to encrypt model ({s})\n", .{@errorName(err)});
        return;
    };

    const mid_str = model.model_id_to_string(&mid);
    print_stdout("model encrypted: {s} -> {s}\n", .{ valid_in, valid_out });
    print_stdout("model id: {s}\n", .{mid_str});
}
