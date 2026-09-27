const std = @import("std");
const base = @import("base");
const hwid = base.hwid;
const license = base.license;
const duration = base.duration;

const c_allocator = std.heap.c_allocator;

export fn read_running_duration(
    file_path: ?[*:0]const u8,
    expected_hwid: ?[*:0]const u8,
    out_total_sec: ?*i64,
    out_last_active_time: ?*i64,
) c_int {
    const p = file_path orelse return -5;
    const path_slice = std.mem.sliceTo(p, 0);
    if (path_slice.len == 0) return -5;

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

    const key = license.derive_hwid_key(hwid_slice);
    const state = duration.read_running_duration_file(path_slice, key) orelse return -1;
    if (out_total_sec) |out_sec| out_sec.* = state.total_sec;
    if (out_last_active_time) |out_time| out_time.* = state.last_active_time;
    return 0;
}

export fn write_running_duration(
    file_path: ?[*:0]const u8,
    expected_hwid: ?[*:0]const u8,
    total_sec: i64,
    last_active_time: i64,
) c_int {
    const p = file_path orelse return -5;
    const path_slice = std.mem.sliceTo(p, 0);
    if (path_slice.len == 0) return -5;

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

    const key = license.derive_hwid_key(hwid_slice);
    const state = duration.RunningDurationState{
        .total_sec = total_sec,
        .last_active_time = last_active_time,
    };
    if (duration.write_running_duration_file(path_slice, key, state)) {
        return 0;
    }
    return -5;
}
