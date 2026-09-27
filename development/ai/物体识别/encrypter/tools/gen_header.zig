const std = @import("std");
const linux = std.os.linux;

fn map_type(fn_name: []const u8, param_name: []const u8, zig_type: []const u8) []const u8 {
    if (std.mem.eql(u8, fn_name, "free_model_memory") and std.mem.eql(u8, param_name, "ptr")) {
        return "uint8_t*";
    }
    if (std.mem.eql(u8, zig_type, "[*]u8") or std.mem.eql(u8, zig_type, "[*c]u8") or std.mem.eql(u8, zig_type, "?[*]u8")) {
        return "char*";
    }
    if (std.mem.eql(u8, zig_type, "usize")) {
        return "size_t";
    }
    if (std.mem.eql(u8, zig_type, "c_int")) {
        return "int";
    }
    if (std.mem.eql(u8, zig_type, "[*:0]const u8") or std.mem.eql(u8, zig_type, "?[*:0]const u8") or std.mem.eql(u8, zig_type, "[*]const u8")) {
        return "const char*";
    }
    if (std.mem.eql(u8, zig_type, "[*]const [*:0]const u8") or
        std.mem.eql(u8, zig_type, "[*]const ?[*:0]const u8") or
        std.mem.eql(u8, zig_type, "[*c]const ?[*:0]const u8") or
        std.mem.eql(u8, zig_type, "[*c]const [*:0]const u8") or
        std.mem.eql(u8, zig_type, "[*]const [*c]const u8") or
        std.mem.eql(u8, zig_type, "[*c]const [*c]const u8")) {
        return "const char* const*";
    }
    if (std.mem.eql(u8, zig_type, "*[*]u8") or std.mem.eql(u8, zig_type, "?*[*]u8")) {
        return "uint8_t**";
    }
    if (std.mem.eql(u8, zig_type, "*usize") or std.mem.eql(u8, zig_type, "?*usize")) {
        return "size_t*";
    }
    if (std.mem.eql(u8, zig_type, "i64")) {
        return "int64_t";
    }
    if (std.mem.eql(u8, zig_type, "*i64") or std.mem.eql(u8, zig_type, "?*i64")) {
        return "int64_t*";
    }
    if (std.mem.eql(u8, zig_type, "*c_int") or std.mem.eql(u8, zig_type, "?*c_int")) {
        return "int*";
    }
    if (std.mem.eql(u8, zig_type, "void")) {
        return "void";
    }
    return zig_type;
}

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    while (start < s.len and (s[start] == ' ' or s[start] == '\t' or s[start] == '\r' or s[start] == '\n')) : (start += 1) {}
    var end: usize = s.len;
    while (end > start and (s[end - 1] == ' ' or s[end - 1] == '\t' or s[end - 1] == '\r' or s[end - 1] == '\n')) : (end -= 1) {}
    return s[start..end];
}

fn append_str(buf: []u8, len: *usize, str: []const u8) void {
    if (len.* + str.len <= buf.len) {
        @memcpy(buf[len.* .. len.* + str.len], str);
        len.* += str.len;
    }
}

fn append_char(buf: []u8, len: *usize, c: u8) void {
    if (len.* + 1 <= buf.len) {
        buf[len.*] = c;
        len.* += 1;
    }
}

fn parse_and_append_signatures(content: []const u8, buf: []u8, len: *usize) void {
    var idx: usize = 0;
    const prefix = "export fn ";
    while (std.mem.indexOfPos(u8, content, idx, prefix)) |start_pos| {
        const fn_start = start_pos + prefix.len;
        const lparen = std.mem.indexOfPos(u8, content, fn_start, "(") orelse break;
        const fn_name = trim(content[fn_start..lparen]);

        const rparen = std.mem.indexOfPos(u8, content, lparen + 1, ")") orelse break;
        const params_str = content[lparen + 1 .. rparen];

        const lbrace = std.mem.indexOfPos(u8, content, rparen + 1, "{") orelse break;
        const ret_raw = trim(content[rparen + 1 .. lbrace]);
        const c_ret = map_type(fn_name, "", ret_raw);

        append_str(buf, len, c_ret);
        append_char(buf, len, ' ');
        append_str(buf, len, fn_name);
        append_char(buf, len, '(');

        const trimmed_params = trim(params_str);
        if (trimmed_params.len == 0) {
            append_str(buf, len, "void");
        } else {
            var first = true;
            var it = std.mem.splitScalar(u8, trimmed_params, ',');
            while (it.next()) |chunk| {
                const part = trim(chunk);
                if (part.len == 0) continue;
                if (!first) {
                    append_str(buf, len, ", ");
                }
                first = false;

                if (std.mem.indexOfScalar(u8, part, ':')) |colon| {
                    const pname = trim(part[0..colon]);
                    const ptype = trim(part[colon + 1 ..]);
                    const c_type = map_type(fn_name, pname, ptype);
                    append_str(buf, len, c_type);
                    append_char(buf, len, ' ');
                    append_str(buf, len, pname);
                } else {
                    append_str(buf, len, part);
                }
            }
        }

        append_str(buf, len, ");\n");
        idx = lbrace + 1;
    }
}

fn read_file_to_buf(path: []const u8, out_buf: []u8) ?usize {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return null;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;

    const fd_res = linux.syscall3(.open, @intFromPtr(&path_z), 0, 0);
    if (@as(isize, @bitCast(fd_res)) < 0) return null;
    const fd = fd_res;
    defer _ = linux.syscall1(.close, fd);

    const rd_res = linux.syscall3(.read, fd, @intFromPtr(out_buf.ptr), out_buf.len);
    if (@as(isize, @bitCast(rd_res)) <= 0) return null;
    return @intCast(rd_res);
}

fn make_parent_dirs(path: []const u8) void {
    var buf: [1024:0]u8 = undefined;
    for (path, 0..) |c, i| {
        if (c == '/' and i > 0) {
            @memcpy(buf[0..i], path[0..i]);
            buf[i] = 0;
            _ = linux.syscall2(.mkdir, @intFromPtr(&buf), 0o755);
        }
    }
}

fn write_file(path: []const u8, content: []const u8) bool {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return false;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;

    const flags: usize = 0x241;
    const fd_res = linux.syscall3(.open, @intFromPtr(&path_z), flags, 0o644);
    if (@as(isize, @bitCast(fd_res)) < 0) return false;
    const fd = fd_res;
    defer _ = linux.syscall1(.close, fd);

    var written: usize = 0;
    while (written < content.len) {
        const rc = linux.syscall3(.write, fd, @intFromPtr(content.ptr + written), content.len - written);
        if (@as(isize, @bitCast(rc)) <= 0) return false;
        written += @as(usize, @intCast(rc));
    }
    return true;
}

fn print_msg(msg: []const u8) void {
    _ = linux.syscall3(.write, 1, @intFromPtr(msg.ptr), msg.len);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

    var body_buf: [16384]u8 = undefined;
    var body_len: usize = 0;

    var file_buf: [32768]u8 = undefined;

    const candidate_prefixes = [_][]const u8{
        "src/c/",
        "encrypter/src/c/",
        "../encrypter/src/c/",
    };

    var base_prefix: []const u8 = "src/c/";
    for (candidate_prefixes) |prefix| {
        var test_path: [128]u8 = undefined;
        @memcpy(test_path[0..prefix.len], prefix);
        @memcpy(test_path[prefix.len .. prefix.len + 8], "hwid.zig");
        if (read_file_to_buf(test_path[0 .. prefix.len + 8], &file_buf) != null) {
            base_prefix = prefix;
            break;
        }
    }

    const file_names = [_][]const u8{
        "duration.zig",
        "hwid.zig",
        "label.zig",
        "license.zig",
        "model.zig",
    };

    for (file_names) |fname| {
        var fpath_buf: [256]u8 = undefined;
        @memcpy(fpath_buf[0..base_prefix.len], base_prefix);
        @memcpy(fpath_buf[base_prefix.len .. base_prefix.len + fname.len], fname);
        const fpath = fpath_buf[0 .. base_prefix.len + fname.len];

        if (read_file_to_buf(fpath, &file_buf)) |sz| {
            parse_and_append_signatures(file_buf[0..sz], &body_buf, &body_len);
        }
    }

    var full_buf: [32768]u8 = undefined;
    var full_len: usize = 0;

    append_str(&full_buf, &full_len,
        "#ifndef MODEL_LICENSE_H\n" ++
        "#define MODEL_LICENSE_H\n\n" ++
        "#include <stddef.h>\n" ++
        "#include <stdint.h>\n\n" ++
        "/* 授权校验状态码 (License Verification Status Codes) */\n" ++
        "#define LICENSE_STATUS_OK               0   /* 验证通过 (Valid) */\n" ++
        "#define LICENSE_STATUS_INVALID_FORMAT  -1   /* 格式损坏或签名认证失败 */\n" ++
        "#define LICENSE_STATUS_HWID_MISMATCH   -2   /* 硬件机器码不匹配 */\n" ++
        "#define LICENSE_STATUS_EXPIRED         -3   /* 证书已到期 */\n" ++
        "#define LICENSE_STATUS_TIME_ROLLBACK   -4   /* 系统时钟异常或早于签发时间 */\n" ++
        "#define LICENSE_STATUS_IO_ERROR        -5   /* 证书文件不存在或无法读取 */\n\n" ++
        "#ifdef __cplusplus\n" ++
        "extern \"C\" {\n" ++
        "#endif\n\n"
    );
    append_str(&full_buf, &full_len, body_buf[0..body_len]);
    append_str(&full_buf, &full_len,
        "\n#ifdef __cplusplus\n" ++
        "}\n" ++
        "#endif\n\n" ++
        "#endif\n"
    );

    const out_targets = if (args.len > 1) args[1..] else &[_][]const u8{"include/model_license.h"};

    for (out_targets) |out_path| {
        make_parent_dirs(out_path);
        if (write_file(out_path, full_buf[0..full_len])) {
            print_msg("[gen_header] Generated ");
            print_msg(out_path);
            print_msg("\n");
        }
    }
}
