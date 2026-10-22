const std = @import("std");
const linux = std.os.linux;

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

fn print_msg(msg: []const u8) void {
    _ = linux.syscall3(.write, 1, @intFromPtr(msg.ptr), msg.len);
}

const ModelTask = struct {
    id: []const u8,
    name: []const u8,
    desc: []const u8,
    resource: []const u8,
};

const tasks = [_]ModelTask{
    .{
        .id = "steel_defect",
        .name = "钢材缺陷检测",
        .desc = "裂纹、夹杂、斑块、麻面、氧化皮压入、划痕缺陷检测",
        .resource = "resources/steel_defect.txt",
    },
    .{
        .id = "forklift_collision",
        .name = "叉车防撞",
        .desc = "工业叉车与作业人员识别及近距离人车碰撞预警",
        .resource = "resources/forklift.txt",
    },
    .{
        .id = "safety_ppe",
        .name = "穿戴检测",
        .desc = "安全帽、反光衣佩戴及违规检测",
        .resource = "resources/safety_ppe.txt",
    },
    .{
        .id = "tile_defect",
        .name = "瓷砖缺陷检测",
        .desc = "边角缺损、黑白斑点、浅深色块、光晕缺陷检测",
        .resource = "resources/tile_defect.txt",
    },
    .{
        .id = "license_plate",
        .name = "车牌识别",
        .desc = "车牌定位和识别",
        .resource = "resources/license_plate.txt",
    },
    .{
        .id = "industry",
        .name = "工业检测",
        .desc = "工业相关（人员/安全穿戴/行为违规/叉车设备/消防隐患）",
        .resource = "resources/industry.txt",
    },
    .{
        .id = "yolo_raw",
        .name = "通用检测",
        .desc = "80 类通用检测",
        .resource = "resources/coco_80_labels_list.txt",
    },
};

const ModelJson = struct {
    id: []const u8,
    name: []const u8,
    desc: []const u8,
    classes: []const []const u8,
};

pub fn main(init: std.process.Init.Minimal) !void {
    const allocator = std.heap.page_allocator;

    var out_dir: []const u8 = "../web/priv/models";
    var it = init.args.iterate();
    _ = it.next();
    if (it.next()) |dir| {
        out_dir = dir;
    }

    for (tasks) |task| {
        var file_buf: [65536]u8 = undefined;
        const sz = read_file_to_buf(task.resource, &file_buf) orelse continue;
        const content = file_buf[0..sz];

        var line_it = std.mem.splitAny(u8, content, "\r\n");
        var class_list: [256][]const u8 = undefined;
        var class_count: usize = 0;

        while (line_it.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r\n");
            if (trimmed.len > 0 and class_count < class_list.len) {
                class_list[class_count] = trimmed;
                class_count += 1;
            }
        }

        const model = ModelJson{
            .id = task.id,
            .name = task.name,
            .desc = task.desc,
            .classes = class_list[0..class_count],
        };

        const json_str = try std.fmt.allocPrint(allocator, "{f}\n", .{
            std.json.fmt(model, .{ .whitespace = .indent_2 }),
        });
        defer allocator.free(json_str);

        var path_buf: [1024]u8 = undefined;
        var len: usize = 0;

        @memcpy(path_buf[len .. len + out_dir.len], out_dir);
        len += out_dir.len;

        if (len > 0 and path_buf[len - 1] != '/') {
            path_buf[len] = '/';
            len += 1;
        }

        @memcpy(path_buf[len .. len + task.id.len], task.id);
        len += task.id.len;

        const ext = ".json";
        @memcpy(path_buf[len .. len + ext.len], ext);
        len += ext.len;

        const full_path = path_buf[0..len];
        make_parent_dirs(full_path);

        if (write_file(full_path, json_str)) {
            print_msg("[gen_web_models] Generated ");
            print_msg(full_path);
            print_msg("\n");
        }
    }
}
