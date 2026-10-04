const std = @import("std");
const base = @import("base");
const crypto = base.crypto;
const license = base.license;
const duration = base.duration;

const cli_print = @import("print.zig");
const print_stdout = cli_print.print_stdout;
const print_stderr = cli_print.print_stderr;
const get_exe_name = cli_print.get_exe_name;

fn print_usage(exe: []const u8) void {
    print_stdout("=========================================================\n", .{});
    print_stdout("用法说明 (Usage):\n", .{});
    print_stdout("  签发授权: {s} sign --hwid <机器码> --lic <证书路径> [--days <天数>]\n", .{exe});
    print_stdout("  校验授权: {s} verify --hwid <机器码> --lic <证书路径>\n", .{exe});
    print_stdout("  读取时长: {s} read-duration --hwid <机器码> --path <文件路径>\n", .{exe});
    print_stdout("=========================================================\n", .{});
}

fn format_remaining_time(remain_sec: i64, buf: []u8) []const u8 {
    if (remain_sec <= 0) {
        return "已过期";
    }
    const days = @divFloor(remain_sec, 86400);
    const rem_day = @mod(remain_sec, 86400);
    const hours = @divFloor(rem_day, 3600);
    const rem_hour = @mod(rem_day, 3600);
    const mins = @divFloor(rem_hour, 60);
    const secs = @mod(rem_hour, 60);

    if (days > 0) {
        if (hours > 0) {
            return std.fmt.bufPrint(buf, "剩余约 {d} 天 {d} 小时", .{ days, hours }) catch "未知";
        } else {
            return std.fmt.bufPrint(buf, "剩余约 {d} 天", .{days}) catch "未知";
        }
    } else if (hours > 0) {
        if (mins > 0) {
            return std.fmt.bufPrint(buf, "剩余约 {d} 小时 {d} 分钟", .{ hours, mins }) catch "未知";
        } else {
            return std.fmt.bufPrint(buf, "剩余约 {d} 小时", .{hours}) catch "未知";
        }
    } else if (mins > 0) {
        if (secs > 0) {
            return std.fmt.bufPrint(buf, "剩余约 {d} 分钟 {d} 秒", .{ mins, secs }) catch "未知";
        } else {
            return std.fmt.bufPrint(buf, "剩余约 {d} 分钟", .{mins}) catch "未知";
        }
    } else {
        return std.fmt.bufPrint(buf, "剩余约 {d} 秒", .{secs}) catch "未知";
    }
}

pub fn main(init: std.process.Init.Minimal) !void {
    const allocator = std.heap.c_allocator;

    var args_buf: [32][]const u8 = undefined;
    var args_len: usize = 0;
    var it = init.args.iterate();
    while (it.next()) |arg| {
        if (args_len < args_buf.len) {
            args_buf[args_len] = arg;
            args_len += 1;
        }
    }
    const args = args_buf[0..args_len];
    const exe = if (args.len > 0) get_exe_name(args[0]) else "license_tool";

    if (args.len < 2) {
        print_usage(exe);
        return;
    }

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "sign")) {
        var hwid_arg: ?[]const u8 = null;
        var lic_file: []const u8 = "license.key";
        var days: i64 = 365;

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            if ((std.mem.eql(u8, args[i], "--hwid") or std.mem.eql(u8, args[i], "--sn")) and i + 1 < args.len) {
                hwid_arg = args[i + 1];
                i += 1;
            } else if ((std.mem.eql(u8, args[i], "--lic") or std.mem.eql(u8, args[i], "--out")) and i + 1 < args.len) {
                lic_file = args[i + 1];
                i += 1;
            } else if (std.mem.eql(u8, args[i], "--days") and i + 1 < args.len) {
                days = std.fmt.parseInt(i64, args[i + 1], 10) catch 365;
                i += 1;
            } else if (!std.mem.startsWith(u8, args[i], "-")) {
                if (hwid_arg == null) {
                    hwid_arg = args[i];
                } else if (std.mem.eql(u8, lic_file, "license.key")) {
                    lic_file = args[i];
                } else if (days == 365) {
                    days = std.fmt.parseInt(i64, args[i], 10) catch 365;
                }
            }
        }

        const valid_hwid = hwid_arg orelse {
            print_stderr("错误: 签发授权必须提供 --hwid 机器码参数\n\n", .{});
            print_usage(exe);
            return;
        };

        license.generate_license(allocator, crypto.DEFAULT_LICENSE_SEED, valid_hwid, days, lic_file) catch |err| {
            print_stderr("错误: 授权证书生成失败 ({s})\n", .{@errorName(err)});
            return;
        };
        var issue_buf: [64]u8 = undefined;
        const now: i64 = @intCast(license.time(null));
        const issue_str = license.format_timestamp(now, &issue_buf);

        print_stdout("=========================================================\n", .{});
        print_stdout("  授权证书签发 (License Sign): {s}\n", .{lic_file});
        print_stdout("=========================================================\n", .{});
        print_stdout("  • 签发状态    : \x1b[32m[PASS] 授权证书生成成功\x1b[0m\n", .{});
        print_stdout("  • 绑定机器码  : {s}\n", .{valid_hwid});
        print_stdout("  • 证书创建时间: {s}\n", .{issue_str});
        if (days > 0) {
            var expire_buf: [64]u8 = undefined;
            const expire_time = now + days * 86400;
            const expire_str = license.format_timestamp(expire_time, &expire_buf);
            print_stdout("  • 证书到期时间: {s} (有效时长: {d} 天)\n", .{ expire_str, days });
        } else {
            print_stdout("  • 证书到期时间: 永久授权 (Permanent)\n", .{});
        }
        print_stdout("=========================================================\n", .{});
        return;
    }

    if (std.mem.eql(u8, cmd, "verify")) {
        var hwid_arg: ?[]const u8 = null;
        var lic_file: []const u8 = "license.key";

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            if ((std.mem.eql(u8, args[i], "--hwid") or std.mem.eql(u8, args[i], "--sn")) and i + 1 < args.len) {
                hwid_arg = args[i + 1];
                i += 1;
            } else if ((std.mem.eql(u8, args[i], "--lic") or std.mem.eql(u8, args[i], "--in") or std.mem.eql(u8, args[i], "--file")) and i + 1 < args.len) {
                lic_file = args[i + 1];
                i += 1;
            } else if (!std.mem.startsWith(u8, args[i], "-")) {
                if (hwid_arg == null) {
                    hwid_arg = args[i];
                } else if (std.mem.eql(u8, lic_file, "license.key")) {
                    lic_file = args[i];
                }
            }
        }

        const valid_hwid = hwid_arg orelse {
            print_stderr("错误: 校验授权必须提供 --hwid 机器码参数\n\n", .{});
            print_usage(exe);
            return;
        };

        const details = license.inspect_license_file_default(allocator, valid_hwid, lic_file);

        var issue_buf: [64]u8 = undefined;
        var expire_buf: [64]u8 = undefined;
        const issue_str = license.format_timestamp(details.issue_time, &issue_buf);
        const expire_str = license.format_timestamp(details.expire_time, &expire_buf);
        const now: i64 = @intCast(license.time(null));

        var effective_status = details.status;
        if (effective_status == .ok and details.expire_time > 0 and now >= details.expire_time) {
            effective_status = .expired;
        }

        print_stdout("=========================================================\n", .{});
        print_stdout("  授权证书信息 (License Info): {s}\n", .{lic_file});
        print_stdout("=========================================================\n", .{});

        switch (effective_status) {
            .ok => {
                print_stdout("  • 校验状态    : \x1b[32m[PASS] 授权验证通过\x1b[0m\n", .{});
                print_stdout("  • 绑定机器码  : {s}\n", .{details.get_hwid()});
                print_stdout("  • 证书创建时间: {s}\n", .{issue_str});
                if (details.expire_time > 0) {
                    const remain_sec = details.expire_time - now;
                    var remain_buf: [64]u8 = undefined;
                    const remain_str = format_remaining_time(remain_sec, &remain_buf);
                    print_stdout("  • 证书到期时间: {s} ({s})\n", .{ expire_str, remain_str });
                } else {
                    print_stdout("  • 证书到期时间: 永久授权 (Permanent)\n", .{});
                }
            },
            .expired => {
                print_stdout("  • 校验状态    : \x1b[31m[FAIL] 授权已过期\x1b[0m\n", .{});
                print_stdout("  • 绑定机器码  : {s}\n", .{details.get_hwid()});
                print_stdout("  • 证书创建时间: {s}\n", .{issue_str});
                print_stdout("  • 证书到期时间: {s} (\x1b[31m已过期\x1b[0m)\n", .{expire_str});
            },
            .time_rollback => {
                print_stdout("  • 校验状态    : \x1b[31m[FAIL] 检测到系统时间被向后回拨/篡改！\x1b[0m\n", .{});
                print_stdout("  • 绑定机器码  : {s}\n", .{details.get_hwid()});
                print_stdout("  • 证书创建时间: {s}\n", .{issue_str});
                print_stdout("  • 证书到期时间: {s}\n", .{expire_str});
            },
            .hwid_mismatch => {
                print_stdout("  • 校验状态    : \x1b[31m[FAIL] 机器码不匹配，解密认证失败！\x1b[0m\n", .{});
                print_stdout("  • 校验目标机器: {s}\n", .{valid_hwid});
            },
            .invalid_format => {
                print_stdout("  • 校验状态    : \x1b[31m[FAIL] 证书格式损坏或不支持该版本\x1b[0m\n", .{});
            },
            .io_error => {
                print_stdout("  • 校验状态    : \x1b[31m[FAIL] 无法打开或读取证书文件: {s}\x1b[0m\n", .{lic_file});
            },
        }
        print_stdout("=========================================================\n", .{});
        return;
    } else if (std.mem.eql(u8, cmd, "read-duration")) {
        var hwid_arg: ?[]const u8 = null;
        var cfg_file: ?[]const u8 = null;

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            if ((std.mem.eql(u8, args[i], "--hwid") or std.mem.eql(u8, args[i], "--sn")) and i + 1 < args.len) {
                hwid_arg = args[i + 1];
                i += 1;
            } else if ((std.mem.eql(u8, args[i], "--path") or std.mem.eql(u8, args[i], "--file")) and i + 1 < args.len) {
                cfg_file = args[i + 1];
                i += 1;
            } else if (!std.mem.startsWith(u8, args[i], "-")) {
                if (hwid_arg == null) {
                    hwid_arg = args[i];
                } else {
                    cfg_file = args[i];
                }
            }
        }

        const valid_hwid = hwid_arg orelse {
            print_stderr("错误: 缺少 --hwid 参数\n", .{});
            print_usage(exe);
            return;
        };

        const cfg_path = cfg_file orelse {
            print_stderr("错误: 缺少 --path 参数指定文件路径\n", .{});
            print_usage(exe);
            return;
        };

        const key = license.derive_hwid_key(valid_hwid);
        const state_opt = duration.read_running_duration_file(cfg_path, key);

        print_stdout("=========================================================\n", .{});
        print_stdout("  运行工时解密读取 (Running Duration): {s}\n", .{cfg_path});
        print_stdout("=========================================================\n", .{});
        if (state_opt) |state| {
            var time_buf: [64]u8 = undefined;
            const last_time_str = license.format_timestamp(state.last_active_time, &time_buf);

            const days = @divFloor(state.total_sec, 86400);
            const rem_d = @mod(state.total_sec, 86400);
            const hours = @divFloor(rem_d, 3600);
            const rem_h = @mod(rem_d, 3600);
            const mins = @divFloor(rem_h, 60);
            const secs = @mod(rem_h, 60);

            print_stdout("  • 解密状态    : \x1b[32m[PASS] 解密读取成功\x1b[0m\n", .{});
            print_stdout("  • 绑定机器码  : {s}\n", .{valid_hwid});
            print_stdout("  • 累计工作时长: {d}天 {d}小时 {d}分钟 {d}秒 (共 {d} 秒)\n", .{
                days, hours, mins, secs, state.total_sec,
            });
            print_stdout("  • 上次活跃时间: {s}\n", .{last_time_str});
        } else {
            print_stdout("  • 解密状态    : \x1b[31m[FAIL] 解密失败或文件不存在/机器码不匹配\x1b[0m\n", .{});
        }
        print_stdout("=========================================================\n", .{});
        return;
    }

    print_usage(exe);
}
