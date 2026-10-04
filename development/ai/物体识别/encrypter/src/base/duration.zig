const std = @import("std");
const crypto = @import("crypto.zig");

pub const RUNNING_DURATION_MAGIC = [4]u8{ 'R', 'U', 'N', 'D' };
pub const RUNNING_DURATION_VERSION: u32 = 1;

pub const RunningDurationState = struct {
    total_sec: i64 = 0,
    last_active_time: i64 = 0,
};

pub fn read_running_duration_file(path: []const u8, hwid_key: [crypto.KEY_LEN]u8) ?RunningDurationState {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return null;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse return null;
    defer _ = std.c.fclose(file);

    const min_len = crypto.NONCE_LEN + crypto.TAG_LEN + 32;
    var buf: [min_len]u8 = undefined;
    const n = std.c.fread(&buf, 1, buf.len, file);
    if (n < min_len) return null;

    const nonce: *const [crypto.NONCE_LEN]u8 = @ptrCast(buf[0..crypto.NONCE_LEN]);
    const tag: *const [crypto.TAG_LEN]u8 = @ptrCast(buf[crypto.NONCE_LEN .. crypto.NONCE_LEN + crypto.TAG_LEN]);
    const cipher = buf[crypto.NONCE_LEN + crypto.TAG_LEN .. min_len];

    var plain: [32]u8 = undefined;
    if (!crypto.decrypt_aead(hwid_key, nonce.*, cipher, tag.*, &plain)) return null;

    if (!std.mem.eql(u8, plain[0..4], &RUNNING_DURATION_MAGIC) and !std.mem.eql(u8, plain[0..4], "RKCF")) return null;
    const total_sec = std.mem.readInt(i64, plain[8..16], .big);
    const last_active = std.mem.readInt(i64, plain[16..24], .big);

    return RunningDurationState{
        .total_sec = total_sec,
        .last_active_time = last_active,
    };
}

pub fn write_running_duration_file(path: []const u8, hwid_key: [crypto.KEY_LEN]u8, state: RunningDurationState) bool {
    var plain: [32]u8 = @splat(0);
    @memcpy(plain[0..4], &RUNNING_DURATION_MAGIC);
    std.mem.writeInt(u32, plain[4..8], RUNNING_DURATION_VERSION, .big);
    std.mem.writeInt(i64, plain[8..16], state.total_sec, .big);
    std.mem.writeInt(i64, plain[16..24], state.last_active_time, .big);

    var nonce: [crypto.NONCE_LEN]u8 = undefined;
    crypto.random_bytes(&nonce);

    var cipher: [32]u8 = undefined;
    var tag: [crypto.TAG_LEN]u8 = undefined;
    crypto.encrypt_aead(hwid_key, nonce, &plain, &cipher, &tag);

    var tmp_path_z: [1024:0]u8 = undefined;
    if (path.len + 4 >= 1024) return false;
    @memcpy(tmp_path_z[0..path.len], path);
    @memcpy(tmp_path_z[path.len .. path.len + 4], ".tmp");
    tmp_path_z[path.len + 4] = 0;

    var path_z: [1024:0]u8 = undefined;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;

    const file = std.c.fopen(&tmp_path_z, "wb") orelse return false;
    _ = std.c.fwrite(&nonce, 1, crypto.NONCE_LEN, file);
    _ = std.c.fwrite(&tag, 1, crypto.TAG_LEN, file);
    _ = std.c.fwrite(&cipher, 1, cipher.len, file);
    _ = std.c.fclose(file);

    return (std.c.rename(&tmp_path_z, &path_z) == 0);
}

test "running duration read write encrypted file" {
    const license = @import("license.zig");
    const hwid = "fdc3-cb9a-cfd0-0d31";
    const cfg_path = "/tmp/test_duration_unit.bin";
    defer _ = std.c.unlink(cfg_path);

    const hwid_key = license.derive_hwid_key(hwid);
    const st1 = RunningDurationState{
        .total_sec = 3600,
        .last_active_time = 1700000000,
    };
    try std.testing.expect(write_running_duration_file(cfg_path, hwid_key, st1));

    const read_back = read_running_duration_file(cfg_path, hwid_key) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(i64, 3600), read_back.total_sec);
    try std.testing.expectEqual(@as(i64, 1700000000), read_back.last_active_time);

    const st2 = RunningDurationState{
        .total_sec = 3660,
        .last_active_time = 1700000060,
    };
    try std.testing.expect(write_running_duration_file(cfg_path, hwid_key, st2));
    const read_back2 = read_running_duration_file(cfg_path, hwid_key) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(@as(i64, 3660), read_back2.total_sec);

    const wrong_key = license.derive_hwid_key("wrong-hwid-9999");
    try std.testing.expect(read_running_duration_file(cfg_path, wrong_key) == null);
}
