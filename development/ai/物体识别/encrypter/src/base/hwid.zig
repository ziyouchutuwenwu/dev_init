const std = @import("std");

fn read_sys_file(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return null;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse return null;
    defer _ = std.c.fclose(file);
    var buf: [1024]u8 = undefined;
    const bytes_read = std.c.fread(&buf, 1, buf.len, file);
    if (bytes_read == 0) return null;
    const trimmed = std.mem.trim(u8, buf[0..bytes_read], " \t\r\n\x00");
    if (trimmed.len == 0) return null;
    return allocator.dupe(u8, trimmed) catch null;
}

pub fn get_chip_id(allocator: std.mem.Allocator) ?[]const u8 {
    const dt_paths = [_][]const u8{
        "/proc/device-tree/serial-number",
        "/sys/firmware/devicetree/base/serial-number",
        "/proc/device-tree/chosen/serial-number",
        "/sys/firmware/devicetree/base/chosen/serial-number",
    };
    for (dt_paths) |path| {
        if (read_sys_file(allocator, path)) |val| {
            var all_zero = true;
            for (val) |c| {
                if (c != '0' and c != 0) {
                    all_zero = false;
                    break;
                }
            }
            if (!all_zero) return val;
            allocator.free(val);
        }
    }
    return null;
}

fn get_emmc_id(allocator: std.mem.Allocator) ?[]const u8 {
    const dir = std.c.opendir("/sys/block") orelse return null;
    defer _ = std.c.closedir(dir);

    var best_name_buf: [64]u8 = undefined;
    var best_name_len: usize = 0;

    while (std.c.readdir(dir)) |ent| {
        const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&ent.name)), 0);
        if (!std.mem.startsWith(u8, name, "mmcblk") or std.mem.indexOfScalar(u8, name, 'p') != null) {
            continue;
        }

        var type_buf: [128]u8 = undefined;
        const type_path = std.fmt.bufPrint(&type_buf, "/sys/block/{s}/device/type", .{name}) catch continue;
        if (read_sys_file(allocator, type_path)) |dev_type| {
            defer allocator.free(dev_type);
            if (!std.mem.eql(u8, dev_type, "MMC")) continue;
        } else continue;

        if (best_name_len == 0 or std.mem.order(u8, name, best_name_buf[0..best_name_len]) == .lt) {
            if (name.len <= best_name_buf.len) {
                @memcpy(best_name_buf[0..name.len], name);
                best_name_len = name.len;
            }
        }
    }

    if (best_name_len == 0) return null;

    var cid_buf: [128]u8 = undefined;
    const cid_path = std.fmt.bufPrint(&cid_buf, "/sys/block/{s}/device/cid", .{best_name_buf[0..best_name_len]}) catch return null;
    return read_sys_file(allocator, cid_path);
}

fn get_nvme_id(allocator: std.mem.Allocator) ?[]const u8 {
    var is_class_nvme = true;
    var dir = std.c.opendir("/sys/class/nvme");
    if (dir == null) {
        is_class_nvme = false;
        dir = std.c.opendir("/sys/block") orelse return null;
    }
    const d = dir.?;
    defer _ = std.c.closedir(d);

    var best_name_buf: [64]u8 = undefined;
    var best_name_len: usize = 0;

    while (std.c.readdir(d)) |ent| {
        const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&ent.name)), 0);
        if (name.len == 0 or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) continue;

        if (is_class_nvme) {
            if (!std.mem.startsWith(u8, name, "nvme")) continue;
        } else {
            if (!std.mem.startsWith(u8, name, "nvme") or !std.mem.endsWith(u8, name, "n1")) continue;
        }

        if (best_name_len == 0 or std.mem.order(u8, name, best_name_buf[0..best_name_len]) == .lt) {
            if (name.len <= best_name_buf.len) {
                @memcpy(best_name_buf[0..name.len], name);
                best_name_len = name.len;
            }
        }
    }

    if (best_name_len == 0) return null;

    var serial_buf: [128]u8 = undefined;
    const serial_path = if (is_class_nvme)
        std.fmt.bufPrint(&serial_buf, "/sys/class/nvme/{s}/serial", .{best_name_buf[0..best_name_len]}) catch return null
    else
        std.fmt.bufPrint(&serial_buf, "/sys/block/{s}/device/serial", .{best_name_buf[0..best_name_len]}) catch return null;

    return read_sys_file(allocator, serial_path);
}

fn get_ssd_id(allocator: std.mem.Allocator) ?[]const u8 {
    const dir = std.c.opendir("/sys/block") orelse return null;
    defer _ = std.c.closedir(dir);

    var best_name_buf: [64]u8 = undefined;
    var best_name_len: usize = 0;

    while (std.c.readdir(dir)) |ent| {
        const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&ent.name)), 0);
        if (name.len < 3 or !std.mem.startsWith(u8, name, "sd")) continue;
        var is_disk_name = true;
        for (name[2..]) |c| {
            if (c < 'a' or c > 'z') {
                is_disk_name = false;
                break;
            }
        }
        if (!is_disk_name) continue;

        var rem_buf: [128]u8 = undefined;
        const rem_path = std.fmt.bufPrint(&rem_buf, "/sys/block/{s}/removable", .{name}) catch continue;
        if (read_sys_file(allocator, rem_path)) |rem| {
            defer allocator.free(rem);
            if (!std.mem.eql(u8, rem, "0")) continue;
        } else continue;

        var link_buf: [1024:0]u8 = undefined;
        var path_z: [128:0]u8 = undefined;
        const block_path = std.fmt.bufPrint(&path_z, "/sys/block/{s}", .{name}) catch continue;
        path_z[block_path.len] = 0;
        const link_len = std.c.readlink(&path_z, &link_buf, link_buf.len - 1);
        if (link_len > 0) {
            const usize_len: usize = @intCast(link_len);
            const link_slice = link_buf[0..usize_len];
            if (std.mem.indexOf(u8, link_slice, "/usb") != null or std.mem.indexOf(u8, link_slice, "/USB") != null) {
                continue;
            }
        }

        if (best_name_len == 0 or std.mem.order(u8, name, best_name_buf[0..best_name_len]) == .lt) {
            if (name.len <= best_name_buf.len) {
                @memcpy(best_name_buf[0..name.len], name);
                best_name_len = name.len;
            }
        }
    }

    if (best_name_len == 0) return null;

    var serial_buf: [128]u8 = undefined;
    const serial_path = std.fmt.bufPrint(&serial_buf, "/sys/block/{s}/device/serial", .{best_name_buf[0..best_name_len]}) catch return null;
    if (read_sys_file(allocator, serial_path)) |serial| {
        return serial;
    }

    var wwid_buf: [128]u8 = undefined;
    const wwid_path = std.fmt.bufPrint(&wwid_buf, "/sys/block/{s}/device/wwid", .{best_name_buf[0..best_name_len]}) catch return null;
    return read_sys_file(allocator, wwid_path);
}

pub fn get_storage_id(allocator: std.mem.Allocator) ?[]const u8 {
    const detectors = [_]*const fn (std.mem.Allocator) ?[]const u8{
        get_emmc_id,
        get_nvme_id,
        get_ssd_id,
    };
    for (detectors) |detect| {
        if (detect(allocator)) |id| return id;
    }
    return null;
}

fn is_valid_mac(mac: []const u8) bool {
    if (mac.len != 17) return false;
    if (std.mem.eql(u8, mac, "00:00:00:00:00:00")) return false;
    if (std.mem.eql(u8, mac, "ff:ff:ff:ff:ff:ff") or std.mem.eql(u8, mac, "FF:FF:FF:FF:FF:FF")) return false;
    return true;
}

fn get_single_nic_mac(allocator: std.mem.Allocator, iface: []const u8) ?[]const u8 {
    var perm_buf: [128]u8 = undefined;
    const perm_path = std.fmt.bufPrint(&perm_buf, "/sys/class/net/{s}/permanent_address", .{iface}) catch return null;
    if (read_sys_file(allocator, perm_path)) |mac| {
        if (is_valid_mac(mac)) return mac;
        allocator.free(mac);
    }

    var addr_buf: [128]u8 = undefined;
    const addr_path = std.fmt.bufPrint(&addr_buf, "/sys/class/net/{s}/address", .{iface}) catch return null;
    if (read_sys_file(allocator, addr_path)) |mac| {
        if (is_valid_mac(mac)) return mac;
        allocator.free(mac);
    }

    return null;
}

pub fn get_nic_id(allocator: std.mem.Allocator) ?[]const u8 {
    const dir = std.c.opendir("/sys/class/net") orelse return null;
    defer _ = std.c.closedir(dir);

    var best_name_buf: [64]u8 = undefined;
    var best_name_len: usize = 0;

    while (std.c.readdir(dir)) |ent| {
        const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&ent.name)), 0);
        if (name.len == 0 or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..") or std.mem.eql(u8, name, "lo")) {
            continue;
        }

        var dev_path_z: [128:0]u8 = undefined;
        const dev_path = std.fmt.bufPrint(&dev_path_z, "/sys/class/net/{s}/device", .{name}) catch continue;
        dev_path_z[dev_path.len] = 0;
        if (std.c.access(&dev_path_z, 0) != 0) continue;

        var type_buf: [128]u8 = undefined;
        const type_path = std.fmt.bufPrint(&type_buf, "/sys/class/net/{s}/type", .{name}) catch continue;
        if (read_sys_file(allocator, type_path)) |t| {
            defer allocator.free(t);
            if (!std.mem.eql(u8, t, "1")) continue;
        } else continue;

        if (best_name_len == 0 or std.mem.order(u8, name, best_name_buf[0..best_name_len]) == .lt) {
            if (name.len <= best_name_buf.len) {
                @memcpy(best_name_buf[0..name.len], name);
                best_name_len = name.len;
            }
        }
    }

    if (best_name_len == 0) return null;
    return get_single_nic_mac(allocator, best_name_buf[0..best_name_len]);
}

pub fn get_hardware_id(allocator: std.mem.Allocator) ![]const u8 {
    const chip_id = get_chip_id(allocator);
    defer if (chip_id) |id| allocator.free(id);

    const storage_id = get_storage_id(allocator);
    defer if (storage_id) |id| allocator.free(id);

    const nic_id = get_nic_id(allocator);
    defer if (nic_id) |id| allocator.free(id);

    if (chip_id == null and storage_id == null and nic_id == null) {
        return error.HardwareIdNotFound;
    }

    var payload_buf: [512]u8 = undefined;
    var payload_len: usize = 0;

    if (chip_id) |c| {
        const piece = std.fmt.bufPrint(payload_buf[payload_len..], "chip={s};", .{c}) catch "";
        payload_len += piece.len;
    }
    if (storage_id) |s| {
        const piece = std.fmt.bufPrint(payload_buf[payload_len..], "storage={s};", .{s}) catch "";
        payload_len += piece.len;
    }
    if (nic_id) |n| {
        const piece = std.fmt.bufPrint(payload_buf[payload_len..], "nic={s};", .{n}) catch "";
        payload_len += piece.len;
    }

    const payload = payload_buf[0..payload_len];

    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(payload, &hash, .{});

    const hex_digits = "0123456789abcdef";
    var hex_buf: [64]u8 = undefined;
    for (hash, 0..) |b, i| {
        hex_buf[i * 2] = hex_digits[b >> 4];
        hex_buf[i * 2 + 1] = hex_digits[b & 0x0f];
    }

    return std.fmt.allocPrint(
        allocator,
        "{s}-{s}-{s}-{s}",
        .{ hex_buf[0..4], hex_buf[4..8], hex_buf[8..12], hex_buf[12..16] },
    );
}
