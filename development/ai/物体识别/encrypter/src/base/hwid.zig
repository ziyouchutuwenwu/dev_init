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

fn read_nvmem_binary(allocator: std.mem.Allocator, path: []const u8) ?[]const u8 {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return null;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse return null;
    defer _ = std.c.fclose(file);
    var buf: [64]u8 = undefined;
    const n = std.c.fread(&buf, 1, buf.len, file);
    if (n == 0) return null;
    var all_zero = true;
    for (buf[0..n]) |b| {
        if (b != 0) {
            all_zero = false;
            break;
        }
    }
    if (all_zero) return null;
    const hex_digits = "0123456789abcdef";
    const hex = allocator.alloc(u8, n * 2) catch return null;
    for (buf[0..n], 0..) |b, i| {
        hex[i * 2] = hex_digits[b >> 4];
        hex[i * 2 + 1] = hex_digits[b & 0x0f];
    }
    return hex;
}

fn get_rk_chip_id(allocator: std.mem.Allocator) ?[]const u8 {
    const rk_paths = [_][]const u8{
        "/sys/bus/nvmem/devices/rockchip-otp0/nvmem",
        "/sys/bus/nvmem/devices/rockchip-efuse0/nvmem",
        "/sys/bus/nvmem/devices/rockchip-otp/nvmem",
        "/sys/bus/nvmem/devices/rockchip-efuse/nvmem",
    };
    for (rk_paths) |path| {
        if (read_nvmem_binary(allocator, path)) |val| {
            return val;
        }
    }
    return null;
}

fn get_generic_chip_id(allocator: std.mem.Allocator) ?[]const u8 {
    return read_sys_file(allocator, "/proc/device-tree/serial-number");
}

pub fn get_chip_id(allocator: std.mem.Allocator) ?[]const u8 {
    const detectors = [_]*const fn (std.mem.Allocator) ?[]const u8{
        get_rk_chip_id,
        get_generic_chip_id,
    };
    for (detectors) |detect| {
        if (detect(allocator)) |id| return id;
    }
    return null;
}

fn get_emmc_id(allocator: std.mem.Allocator) ?[]const u8 {
    const mmc_nodes = [_][]const u8{ "mmcblk0", "mmcblk1", "mmcblk2" };
    for (mmc_nodes) |node| {
        var type_buf: [128]u8 = undefined;
        const type_path = std.fmt.bufPrint(&type_buf, "/sys/block/{s}/device/type", .{node}) catch continue;
        if (read_sys_file(allocator, type_path)) |dev_type| {
            defer allocator.free(dev_type);
            if (std.mem.eql(u8, dev_type, "MMC")) {
                var cid_buf: [128]u8 = undefined;
                const cid_path = std.fmt.bufPrint(&cid_buf, "/sys/block/{s}/device/cid", .{node}) catch continue;
                if (read_sys_file(allocator, cid_path)) |cid| {
                    return cid;
                }
            }
        }
    }
    return null;
}

fn get_nvme_id(allocator: std.mem.Allocator) ?[]const u8 {
    const nvme_paths = [_][]const u8{
        "/sys/block/nvme0n1/device/serial",
        "/sys/block/nvme1n1/device/serial",
    };
    for (nvme_paths) |path| {
        if (read_sys_file(allocator, path)) |serial| {
            return serial;
        }
    }
    return null;
}

fn get_ssd_id(allocator: std.mem.Allocator) ?[]const u8 {
    const ssd_paths = [_][]const u8{
        "/sys/block/sda/device/serial",
        "/sys/block/sdb/device/serial",
    };
    for (ssd_paths) |path| {
        if (read_sys_file(allocator, path)) |serial| {
            return serial;
        }
    }
    return null;
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

pub fn get_hardware_id(allocator: std.mem.Allocator) ![]const u8 {
    const chip_id = get_chip_id(allocator);
    defer if (chip_id) |id| allocator.free(id);

    const storage_id = get_storage_id(allocator);
    defer if (storage_id) |id| allocator.free(id);

    if (chip_id == null and storage_id == null) {
        return error.HardwareIdNotFound;
    }

    const payload = if (chip_id != null and storage_id != null)
        try std.fmt.allocPrint(allocator, "chip={s};storage={s}", .{ chip_id.?, storage_id.? })
    else if (chip_id != null)
        try std.fmt.allocPrint(allocator, "chip={s}", .{chip_id.?})
    else
        try std.fmt.allocPrint(allocator, "storage={s}", .{storage_id.?});
    defer allocator.free(payload);

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
