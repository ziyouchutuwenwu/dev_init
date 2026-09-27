const std = @import("std");
const base = @import("base");
const crypto = base.crypto;
const hwid = base.hwid;
const license = base.license;

const c_allocator = std.heap.c_allocator;

export fn verify_license(
    license_path: ?[*:0]const u8,
    expected_hwid: ?[*:0]const u8,
) c_int {
    const path = license_path orelse return -5;
    const lic_path_slice = std.mem.sliceTo(path, 0);

    var hwid_slice: []const u8 = "";
    var auto_hwid: ?[]const u8 = null;
    defer if (auto_hwid) |s| c_allocator.free(s);

    if (expected_hwid) |ptr| {
        hwid_slice = std.mem.sliceTo(ptr, 0);
    }

    if (hwid_slice.len == 0) {
        auto_hwid = hwid.get_hardware_id(c_allocator) catch return -2;
        hwid_slice = auto_hwid.?;
    }

    const details = license.inspect_license_file_default(c_allocator, hwid_slice, lic_path_slice);
    return @intFromEnum(details.status);
}

export fn inspect_license_details(
    license_path: ?[*:0]const u8,
    expected_hwid: ?[*:0]const u8,
    out_status: ?*c_int,
    out_issue: ?*i64,
    out_expire: ?*i64,
    out_bound_hwid: ?[*]u8,
    max_hwid_len: usize,
) c_int {
    const path = license_path orelse return -5;
    const lic_path_slice = std.mem.sliceTo(path, 0);

    var hwid_slice: []const u8 = "";
    var auto_hwid: ?[]const u8 = null;
    defer if (auto_hwid) |s| c_allocator.free(s);

    if (expected_hwid) |ptr| {
        hwid_slice = std.mem.sliceTo(ptr, 0);
    }

    if (hwid_slice.len == 0) {
        auto_hwid = hwid.get_hardware_id(c_allocator) catch return -2;
        hwid_slice = auto_hwid.?;
    }

    const details = license.inspect_license_file_default(c_allocator, hwid_slice, lic_path_slice);
    const status_val = @intFromEnum(details.status);
    if (out_status) |p| p.* = status_val;
    if (out_issue) |p| p.* = details.issue_time;
    if (out_expire) |p| p.* = details.expire_time;
    if (out_bound_hwid) |buf| {
        if (max_hwid_len > 0) {
            const bound = details.get_hwid();
            const copy_len = @min(bound.len, max_hwid_len - 1);
            if (copy_len > 0) {
                @memcpy(buf[0..copy_len], bound[0..copy_len]);
            }
            buf[copy_len] = 0;
        }
    }
    return status_val;
}



