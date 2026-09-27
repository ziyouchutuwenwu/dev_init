const std = @import("std");
const crypto = @import("crypto.zig");

pub const LICENSE_SALT = "rk_license_hwid_salt_v2#secure";

pub const VerifyResult = enum(c_int) {
    ok = 0,
    invalid_format = -1,
    hwid_mismatch = -2,
    expired = -3,
    time_rollback = -4,
    io_error = -5,
};

pub fn derive_hwid_key(hwid_str: []const u8) [crypto.KEY_LEN]u8 {
    const trimmed = std.mem.trim(u8, hwid_str, &std.ascii.whitespace);
    var hasher = crypto.Sha256.init(.{});
    var lower_buf: [128]u8 = undefined;
    var i: usize = 0;
    while (i < trimmed.len) {
        const chunk_len = @min(trimmed.len - i, lower_buf.len);
        for (trimmed[i .. i + chunk_len], 0..) |c, j| {
            lower_buf[j] = std.ascii.toLower(c);
        }
        hasher.update(lower_buf[0..chunk_len]);
        i += chunk_len;
    }
    hasher.update(LICENSE_SALT);
    var key: [crypto.KEY_LEN]u8 = undefined;
    hasher.final(&key);
    return key;
}

pub fn generate_license(
    allocator: std.mem.Allocator,
    priv_seed: [crypto.KEY_LEN]u8,
    hwid_str: []const u8,
    days: i64,
    out_path: []const u8,
) !void {
    const key_pair = try crypto.generate_key_pair(priv_seed);
    const now: i64 = @intCast(time(null));
    const expire = if (days > 0) now + days * 86400 else 0;

    const trimmed_hwid = std.mem.trim(u8, hwid_str, &std.ascii.whitespace);
    const payload = try std.fmt.allocPrint(allocator, "hwid={s};issue={d};expire={d}", .{ trimmed_hwid, now, expire });
    defer allocator.free(payload);

    const sig = try crypto.sign_message(key_pair, payload);

    const total_plain_len = 4 + payload.len + crypto.SIG_LEN;
    const plain = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(plain);

    std.mem.writeInt(u32, plain[0..4], @as(u32, @intCast(payload.len)), .big);
    @memcpy(plain[4 .. 4 + payload.len], payload);
    @memcpy(plain[4 + payload.len ..], &sig);

    const hwid_key = derive_hwid_key(trimmed_hwid);
    var nonce: [crypto.NONCE_LEN]u8 = undefined;
    crypto.random_bytes(&nonce);

    const cipher = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(cipher);
    var tag: [crypto.TAG_LEN]u8 = undefined;

    crypto.encrypt_aead(hwid_key, nonce, plain, cipher, &tag);

    var path_z: [1024:0]u8 = undefined;
    if (out_path.len >= 1024) return error.NameTooLong;
    @memcpy(path_z[0..out_path.len], out_path);
    path_z[out_path.len] = 0;
    const file = std.c.fopen(&path_z, "wb") orelse return error.AccessDenied;
    defer _ = std.c.fclose(file);

    if (std.c.fwrite(&nonce, 1, crypto.NONCE_LEN, file) != crypto.NONCE_LEN) return error.WriteFailed;
    if (std.c.fwrite(&tag, 1, crypto.TAG_LEN, file) != crypto.TAG_LEN) return error.WriteFailed;
    if (std.c.fwrite(cipher.ptr, 1, cipher.len, file) != cipher.len) return error.WriteFailed;
}

pub fn generate_license_default(
    allocator: std.mem.Allocator,
    hwid_str: []const u8,
    days: i64,
    out_path: []const u8,
) !void {
    return generate_license(allocator, crypto.DEFAULT_LICENSE_SEED, hwid_str, days, out_path);
}

pub fn verify_license_file_default(
    allocator: std.mem.Allocator,
    expected_hwid: []const u8,
    license_path: []const u8,
) !bool {
    return verify_license_file(allocator, crypto.DEFAULT_LICENSE_PUBKEY, expected_hwid, license_path);
}

pub const LicenseDetails = struct {
    hwid: [128]u8 = [_]u8{0} ** 128,
    hwid_len: usize = 0,
    issue_time: i64 = 0,
    expire_time: i64 = 0,
    status: VerifyResult = .invalid_format,

    pub fn get_hwid(self: *const LicenseDetails) []const u8 {
        return self.hwid[0..self.hwid_len];
    }
};

extern "c" fn fseek(stream: *anyopaque, offset: c_long, whence: c_int) c_int;
extern "c" fn ftell(stream: *anyopaque) c_long;
pub extern "c" fn time(t: ?*c_long) c_long;
pub extern "c" fn localtime(timer: *const c_long) ?*anyopaque;
pub extern "c" fn strftime(s: [*]u8, maxsize: usize, format: [*:0]const u8, timeptr: *const anyopaque) usize;

pub fn format_timestamp(ts: i64, buf: []u8) []const u8 {
    if (ts <= 0) return "永久有效 (Permanent)";
    const c_ts: c_long = @intCast(ts);
    const tm_ptr = localtime(&c_ts) orelse return "unknown";
    const n = strftime(buf.ptr, buf.len, "%Y-%m-%d %H:%M:%S", tm_ptr);
    if (n == 0) return "unknown";
    return buf[0..n];
}



pub fn inspect_license_file(
    allocator: std.mem.Allocator,
    pubkey: [crypto.PUBKEY_LEN]u8,
    expected_hwid: []const u8,
    license_path: []const u8,
) LicenseDetails {
    var details = LicenseDetails{};

    var path_z: [1024:0]u8 = undefined;
    if (license_path.len >= 1024) {
        details.status = .io_error;
        return details;
    }
    @memcpy(path_z[0..license_path.len], license_path);
    path_z[license_path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse {
        details.status = .io_error;
        return details;
    };
    defer _ = std.c.fclose(file);

    _ = fseek(@ptrCast(file), 0, 2);
    const size = ftell(@ptrCast(file));
    _ = fseek(@ptrCast(file), 0, 0);
    if (size <= 0 or size > 1024 * 64) {
        details.status = .invalid_format;
        return details;
    }
    const usize_len: usize = @intCast(size);
    const data = allocator.alloc(u8, usize_len) catch {
        details.status = .io_error;
        return details;
    };
    defer allocator.free(data);
    const n = std.c.fread(data.ptr, 1, usize_len, file);
    if (n != usize_len) {
        details.status = .io_error;
        return details;
    }

    const min_len = crypto.NONCE_LEN + crypto.TAG_LEN + 4 + crypto.SIG_LEN;
    if (data.len < min_len) {
        details.status = .invalid_format;
        return details;
    }

    const hwid_key = derive_hwid_key(expected_hwid);
    const nonce: *const [crypto.NONCE_LEN]u8 = @ptrCast(data[0..crypto.NONCE_LEN]);
    const tag: *const [crypto.TAG_LEN]u8 = @ptrCast(data[crypto.NONCE_LEN .. crypto.NONCE_LEN + crypto.TAG_LEN]);
    const cipher = data[crypto.NONCE_LEN + crypto.TAG_LEN ..];

    const plain = allocator.alloc(u8, cipher.len) catch {
        details.status = .io_error;
        return details;
    };
    defer allocator.free(plain);

    if (!crypto.decrypt_aead(hwid_key, nonce.*, cipher, tag.*, plain)) {
        details.status = .hwid_mismatch;
        return details;
    }

    const payload_len = std.mem.readInt(u32, plain[0..4], .big);
    if (plain.len < 4 + payload_len + crypto.SIG_LEN) {
        details.status = .invalid_format;
        return details;
    }

    const payload = plain[4 .. 4 + payload_len];
    const sig_bytes: *const [crypto.SIG_LEN]u8 = @ptrCast(plain[4 + payload_len ..][0..crypto.SIG_LEN]);

    if (!crypto.verify_signature(sig_bytes.*, pubkey, payload)) {
        details.status = .invalid_format;
        return details;
    }

    var parsed_hwid: ?[]const u8 = null;
    var parsed_issue: i64 = 0;
    var parsed_expire: i64 = 0;

    var iter = std.mem.splitScalar(u8, payload, ';');
    while (iter.next()) |item| {
        if (std.mem.startsWith(u8, item, "hwid=")) {
            parsed_hwid = item[5..];
        } else if (std.mem.startsWith(u8, item, "sn=")) {
            parsed_hwid = item[3..];
        } else if (std.mem.startsWith(u8, item, "issue=")) {
            parsed_issue = std.fmt.parseInt(i64, item[6..], 10) catch 0;
        } else if (std.mem.startsWith(u8, item, "expire=")) {
            parsed_expire = std.fmt.parseInt(i64, item[7..], 10) catch 0;
        }
    }

    if (parsed_hwid) |h| {
        const copy_len = @min(h.len, details.hwid.len);
        @memcpy(details.hwid[0..copy_len], h[0..copy_len]);
        details.hwid_len = copy_len;
    }
    details.issue_time = parsed_issue;
    details.expire_time = parsed_expire;

    const trimmed_expected_hwid = std.mem.trim(u8, expected_hwid, &std.ascii.whitespace);
    const trimmed_valid_hwid = std.mem.trim(u8, details.get_hwid(), &std.ascii.whitespace);

    if (trimmed_expected_hwid.len == 0 or !std.ascii.eqlIgnoreCase(trimmed_valid_hwid, trimmed_expected_hwid)) {
        details.status = .hwid_mismatch;
        return details;
    }

    const now: i64 = @intCast(time(null));

    if (parsed_issue > 0 and now < (parsed_issue - 300)) {
        details.status = .time_rollback;
        return details;
    }

    if (parsed_expire > 0 and now >= parsed_expire) {
        details.status = .expired;
        return details;
    }

    details.status = .ok;
    return details;
}

pub fn inspect_license_file_default(
    allocator: std.mem.Allocator,
    expected_hwid: []const u8,
    license_path: []const u8,
) LicenseDetails {
    return inspect_license_file(allocator, crypto.DEFAULT_LICENSE_PUBKEY, expected_hwid, license_path);
}

pub fn verify_license_file(
    allocator: std.mem.Allocator,
    pubkey: [crypto.PUBKEY_LEN]u8,
    expected_hwid: []const u8,
    license_path: []const u8,
) !bool {
    const details = inspect_license_file(allocator, pubkey, expected_hwid, license_path);
    return details.status == .ok;
}

pub fn verify_license_bytes(
    allocator: std.mem.Allocator,
    pubkey: [crypto.PUBKEY_LEN]u8,
    expected_hwid: []const u8,
    data: []const u8,
) !bool {
    // Fully encrypted AEAD format only: [Nonce: 12] + [Tag: 16] + [Ciphertext: min 4+1+64]
    const min_len = crypto.NONCE_LEN + crypto.TAG_LEN + 4 + crypto.SIG_LEN;
    if (data.len < min_len) return false;

    const hwid_key = derive_hwid_key(expected_hwid);
    const nonce: *const [crypto.NONCE_LEN]u8 = @ptrCast(data[0..crypto.NONCE_LEN]);
    const tag: *const [crypto.TAG_LEN]u8 = @ptrCast(data[crypto.NONCE_LEN .. crypto.NONCE_LEN + crypto.TAG_LEN]);
    const cipher = data[crypto.NONCE_LEN + crypto.TAG_LEN ..];

    const plain = allocator.alloc(u8, cipher.len) catch return false;
    defer allocator.free(plain);

    // Decrypt using ChaCha20-Poly1305. Tag failure indicates wrong HWID or corrupted data
    if (!crypto.decrypt_aead(hwid_key, nonce.*, cipher, tag.*, plain)) {
        return false;
    }

    const payload_len = std.mem.readInt(u32, plain[0..4], .big);
    if (plain.len < 4 + payload_len + crypto.SIG_LEN) return false;

    const payload = plain[4 .. 4 + payload_len];
    const sig_bytes: *const [crypto.SIG_LEN]u8 = @ptrCast(plain[4 + payload_len ..][0..crypto.SIG_LEN]);

    if (!crypto.verify_signature(sig_bytes.*, pubkey, payload)) return false;

    var parsed_hwid: ?[]const u8 = null;
    var parsed_issue: i64 = 0;
    var parsed_expire: i64 = 0;

    var iter = std.mem.splitScalar(u8, payload, ';');
    while (iter.next()) |item| {
        if (std.mem.startsWith(u8, item, "hwid=")) {
            parsed_hwid = item[5..];
        } else if (std.mem.startsWith(u8, item, "sn=")) {
            parsed_hwid = item[3..];
        } else if (std.mem.startsWith(u8, item, "issue=")) {
            parsed_issue = std.fmt.parseInt(i64, item[6..], 10) catch return false;
        } else if (std.mem.startsWith(u8, item, "expire=")) {
            parsed_expire = std.fmt.parseInt(i64, item[7..], 10) catch return false;
        }
    }

    const valid_hwid = parsed_hwid orelse return false;
    const trimmed_expected_hwid = std.mem.trim(u8, expected_hwid, &std.ascii.whitespace);
    const trimmed_valid_hwid = std.mem.trim(u8, valid_hwid, &std.ascii.whitespace);

    if (trimmed_expected_hwid.len == 0 or !std.ascii.eqlIgnoreCase(trimmed_valid_hwid, trimmed_expected_hwid)) {
        return false;
    }

    const now: i64 = @intCast(time(null));

    if (parsed_issue > 0 and now < (parsed_issue - 300)) {
        return false;
    }

    if (parsed_expire > 0 and now >= parsed_expire) {
        return false;
    }

    return true;
}

test "derive_hwid_key case insensitivity" {
    const k1 = derive_hwid_key("fdc3-cb9a-cfd0-0d31");
    const k2 = derive_hwid_key("FDC3-CB9A-CFD0-0D31");
    const k3 = derive_hwid_key("  fdc3-cb9a-cfd0-0d31  \n");
    try std.testing.expectEqualSlices(u8, &k1, &k2);
    try std.testing.expectEqualSlices(u8, &k1, &k3);
}

test "full-file AEAD license generation and verification" {
    const allocator = std.testing.allocator;
    const hwid = "fdc3-cb9a-cfd0-0d31";
    const lic_path = "/tmp/test_unit_lic.key";
    defer std.fs.deleteFileAbsolute(lic_path) catch {};

    try generate_license_default(allocator, hwid, 30, lic_path);

    // Verify correct HWID passes
    const ok = try verify_license_file_default(allocator, hwid, lic_path);
    try std.testing.expect(ok);

    // Verify wrong HWID fails
    const ok_wrong = try verify_license_file_default(allocator, "wrong-hwid-1234", lic_path);
    try std.testing.expect(!ok_wrong);
}

test "anti-rollback rejects future issue time" {
    const allocator = std.testing.allocator;
    const hwid = "fdc3-cb9a-cfd0-0d31";
    const lic_path = "/tmp/test_future_issue.key";
    defer std.fs.deleteFileAbsolute(lic_path) catch {};

    const key_pair = try crypto.generate_key_pair(crypto.DEFAULT_LICENSE_SEED);
    const payload = "hwid=fdc3-cb9a-cfd0-0d31;issue=3000000000;expire=4000000000";
    const sig = try crypto.sign_message(key_pair, payload);

    const total_plain_len = 4 + payload.len + crypto.SIG_LEN;
    const plain = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(plain);
    std.mem.writeInt(u32, plain[0..4], @as(u32, @intCast(payload.len)), .big);
    @memcpy(plain[4 .. 4 + payload.len], payload);
    @memcpy(plain[4 + payload.len ..], &sig);

    const hwid_key = derive_hwid_key(hwid);
    var nonce: [crypto.NONCE_LEN]u8 = undefined;
    crypto.random_bytes(&nonce);
    const cipher = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(cipher);
    var tag: [crypto.TAG_LEN]u8 = undefined;
    crypto.encrypt_aead(hwid_key, nonce, plain, cipher, &tag);

    const file = std.c.fopen(lic_path, "wb") orelse return error.AccessDenied;
    _ = std.c.fwrite(&nonce, 1, crypto.NONCE_LEN, file);
    _ = std.c.fwrite(&tag, 1, crypto.TAG_LEN, file);
    _ = std.c.fwrite(cipher.ptr, 1, cipher.len, file);
    _ = std.c.fclose(file);

    const ok = try verify_license_file_default(allocator, hwid, lic_path);
    try std.testing.expect(!ok);
}



test "legacy plaintext license format is rejected" {
    const allocator = std.testing.allocator;
    const hwid = "fdc3-cb9a-cfd0-0d31";
    const legacy_data = "lic_encrypted\x00\x00\x00\x00\x20hwid=fdc3-cb9a-cfd0-0d31;expire=9999999999";
    const ok = try verify_license_bytes(allocator, crypto.DEFAULT_LICENSE_PUBKEY, hwid, legacy_data);
    try std.testing.expect(!ok);
}
test "inspect_license_file detects expired license" {
    const allocator = std.testing.allocator;
    const hwid = "fdc3-cb9a-cfd0-0d31";
    const lic_path = "/tmp/test_expired.key";
    defer std.fs.deleteFileAbsolute(lic_path) catch {};

    const key_pair = try crypto.generate_key_pair(crypto.DEFAULT_LICENSE_SEED);
    const now: i64 = @intCast(time(null));
    // Issue was 10 days ago, expired 5 days ago
    const past_issue = now - 864000;
    const past_expire = now - 432000;
    const payload = try std.fmt.allocPrint(allocator, "hwid={s};issue={d};expire={d}", .{ hwid, past_issue, past_expire });
    defer allocator.free(payload);

    const sig = try crypto.sign_message(key_pair, payload);
    const total_plain_len = 4 + payload.len + crypto.SIG_LEN;
    const plain = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(plain);

    std.mem.writeInt(u32, plain[0..4], @as(u32, @intCast(payload.len)), .big);
    @memcpy(plain[4 .. 4 + payload.len], payload);
    @memcpy(plain[4 + payload.len ..], &sig);

    const hwid_key = derive_hwid_key(hwid);
    var nonce: [crypto.NONCE_LEN]u8 = undefined;
    crypto.random_bytes(&nonce);
    const cipher = try allocator.alloc(u8, total_plain_len);
    defer allocator.free(cipher);
    var tag: [crypto.TAG_LEN]u8 = undefined;
    crypto.encrypt_aead(hwid_key, nonce, plain, cipher, &tag);

    const file = std.c.fopen(lic_path, "wb") orelse return error.AccessDenied;
    _ = std.c.fwrite(&nonce, 1, crypto.NONCE_LEN, file);
    _ = std.c.fwrite(&tag, 1, crypto.TAG_LEN, file);
    _ = std.c.fwrite(cipher.ptr, 1, cipher.len, file);
    _ = std.c.fclose(file);

    const details = inspect_license_file_default(allocator, hwid, lic_path);
    try std.testing.expectEqual(VerifyResult.expired, details.status);
}
