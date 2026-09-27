const std = @import("std");
const crypto = @import("crypto.zig");

pub const MAGIC = "model_encrypted\x00";
pub const MODEL_ID_LEN: usize = 16;
pub const HEADER_LEN: usize = MAGIC.len + MODEL_ID_LEN + crypto.NONCE_LEN + crypto.TAG_LEN + 8;

extern "c" fn fseek(stream: *anyopaque, offset: c_long, whence: c_int) c_int;
extern "c" fn ftell(stream: *anyopaque) c_long;

pub fn read_model_id_from_file(path: []const u8) ![MODEL_ID_LEN]u8 {
    var path_z: [1024:0]u8 = undefined;
    if (path.len >= 1024) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse return error.FileNotFound;
    defer _ = std.c.fclose(file);
    var header_buf: [HEADER_LEN]u8 = undefined;
    const rd = std.c.fread(&header_buf, 1, HEADER_LEN, file);
    if (rd < 8 + MODEL_ID_LEN) return error.InvalidFileFormat;
    var magic_len: usize = 0;
    if (rd >= MAGIC.len + MODEL_ID_LEN and std.mem.startsWith(u8, header_buf[0..rd], MAGIC)) {
        magic_len = MAGIC.len;
    } else if (std.mem.startsWith(u8, header_buf[0..rd], "rkmod02\x00")) {
        magic_len = 8;
    } else {
        return error.InvalidMagic;
    }
    var id: [MODEL_ID_LEN]u8 = undefined;
    @memcpy(&id, header_buf[magic_len .. magic_len + MODEL_ID_LEN]);
    return id;
}

pub fn read_model_id_from_buffer(data: []const u8) ![MODEL_ID_LEN]u8 {
    if (data.len < 8 + MODEL_ID_LEN) return error.InvalidFileFormat;
    var magic_len: usize = 0;
    if (data.len >= MAGIC.len + MODEL_ID_LEN and std.mem.startsWith(u8, data, MAGIC)) {
        magic_len = MAGIC.len;
    } else if (std.mem.startsWith(u8, data, "rkmod02\x00")) {
        magic_len = 8;
    } else {
        return error.InvalidMagic;
    }
    var id: [MODEL_ID_LEN]u8 = undefined;
    @memcpy(&id, data[magic_len .. magic_len + MODEL_ID_LEN]);
    return id;
}

pub fn encrypt_model_with_id(
    allocator: std.mem.Allocator,
    in_rknn_path: []const u8,
    out_enc_path: []const u8,
    key: [crypto.KEY_LEN]u8,
    model_id: [MODEL_ID_LEN]u8,
) !void {
    var in_path_z: [1024:0]u8 = undefined;
    if (in_rknn_path.len >= 1024) return error.NameTooLong;
    @memcpy(in_path_z[0..in_rknn_path.len], in_rknn_path);
    in_path_z[in_rknn_path.len] = 0;
    const in_file = std.c.fopen(&in_path_z, "rb") orelse return error.FileNotFound;
    defer _ = std.c.fclose(in_file);

    _ = fseek(@ptrCast(in_file), 0, 2);
    const size = ftell(@ptrCast(in_file));
    _ = fseek(@ptrCast(in_file), 0, 0);
    if (size <= 0) return error.InvalidFileFormat;
    const plain_len: usize = @intCast(size);
    const plain_data = try allocator.alloc(u8, plain_len);
    defer {
        std.crypto.secureZero(u8, plain_data);
        allocator.free(plain_data);
    }
    const rd = std.c.fread(plain_data.ptr, 1, plain_len, in_file);
    if (rd != plain_len) return error.ReadFailed;

    var nonce: [crypto.NONCE_LEN]u8 = undefined;
    crypto.random_bytes(&nonce);

    const cipher_buf = try allocator.alloc(u8, plain_data.len);
    defer {
        std.crypto.secureZero(u8, cipher_buf);
        allocator.free(cipher_buf);
    }

    var tag: [crypto.TAG_LEN]u8 = undefined;
    crypto.encrypt_aead(key, nonce, plain_data, cipher_buf, &tag);

    var out_path_z: [1024:0]u8 = undefined;
    if (out_enc_path.len >= 1024) return error.NameTooLong;
    @memcpy(out_path_z[0..out_enc_path.len], out_enc_path);
    out_path_z[out_enc_path.len] = 0;
    const out_file = std.c.fopen(&out_path_z, "wb") orelse return error.AccessDenied;
    defer _ = std.c.fclose(out_file);

    if (std.c.fwrite(MAGIC.ptr, 1, MAGIC.len, out_file) != MAGIC.len) return error.WriteFailed;
    if (std.c.fwrite(&model_id, 1, model_id.len, out_file) != model_id.len) return error.WriteFailed;
    if (std.c.fwrite(&nonce, 1, nonce.len, out_file) != nonce.len) return error.WriteFailed;
    if (std.c.fwrite(&tag, 1, tag.len, out_file) != tag.len) return error.WriteFailed;

    var size_buf: [8]u8 = undefined;
    std.mem.writeInt(u64, &size_buf, @as(u64, @intCast(plain_data.len)), .big);
    if (std.c.fwrite(&size_buf, 1, 8, out_file) != 8) return error.WriteFailed;
    if (std.c.fwrite(cipher_buf.ptr, 1, cipher_buf.len, out_file) != cipher_buf.len) return error.WriteFailed;
}

pub fn encrypt_model(
    allocator: std.mem.Allocator,
    in_rknn_path: []const u8,
    out_enc_path: []const u8,
    key: [crypto.KEY_LEN]u8,
) ![MODEL_ID_LEN]u8 {
    var model_id: [MODEL_ID_LEN]u8 = undefined;
    crypto.random_bytes(&model_id);
    try encrypt_model_with_id(allocator, in_rknn_path, out_enc_path, key, model_id);
    return model_id;
}

pub fn encrypt_model_default(
    allocator: std.mem.Allocator,
    in_rknn_path: []const u8,
    out_enc_path: []const u8,
) ![MODEL_ID_LEN]u8 {
    return encrypt_model(allocator, in_rknn_path, out_enc_path, crypto.DEFAULT_MODEL_KEY);
}

pub fn decrypt_model_to_memory_default(
    allocator: std.mem.Allocator,
    enc_path: []const u8,
) ![]u8 {
    return decrypt_model_to_memory(allocator, enc_path, crypto.DEFAULT_MODEL_KEY);
}

pub fn decrypt_model_to_memory(
    allocator: std.mem.Allocator,
    enc_path: []const u8,
    key: [crypto.KEY_LEN]u8,
) ![]u8 {
    var path_z: [1024:0]u8 = undefined;
    if (enc_path.len >= 1024) return error.NameTooLong;
    @memcpy(path_z[0..enc_path.len], enc_path);
    path_z[enc_path.len] = 0;
    const file = std.c.fopen(&path_z, "rb") orelse return error.FileNotFound;
    defer _ = std.c.fclose(file);

    _ = fseek(@ptrCast(file), 0, 2);
    const size = ftell(@ptrCast(file));
    _ = fseek(@ptrCast(file), 0, 0);
    if (size <= 0) return error.InvalidFileFormat;
    const enc_len: usize = @intCast(size);
    const enc_data = try allocator.alloc(u8, enc_len);
    defer allocator.free(enc_data);
    const rd = std.c.fread(enc_data.ptr, 1, enc_len, file);
    if (rd != enc_len) return error.ReadFailed;

    return decrypt_model_buffer(allocator, enc_data, key);
}

pub fn decrypt_model_buffer(
    allocator: std.mem.Allocator,
    enc_data: []const u8,
    key: [crypto.KEY_LEN]u8,
) ![]u8 {
    if (enc_data.len < 8) return error.InvalidFileFormat;

    var offset: usize = 0;
    if (enc_data.len >= MAGIC.len and std.mem.startsWith(u8, enc_data, MAGIC)) {
        offset = MAGIC.len + MODEL_ID_LEN;
    } else if (std.mem.startsWith(u8, enc_data, "rkmod02\x00")) {
        offset = 8 + MODEL_ID_LEN;
    } else if (std.mem.startsWith(u8, enc_data, "rkmod01\x00")) {
        offset = 8;
    } else {
        return error.InvalidMagic;
    }

    if (enc_data.len < offset + crypto.NONCE_LEN + crypto.TAG_LEN + 8) {
        return error.InvalidFileFormat;
    }

    const nonce = enc_data[offset..][0..crypto.NONCE_LEN].*;
    offset += crypto.NONCE_LEN;

    const tag = enc_data[offset..][0..crypto.TAG_LEN].*;
    offset += crypto.TAG_LEN;

    const expected_size = std.mem.readInt(u64, enc_data[offset..][0..8], .big);
    offset += 8;

    const ciphertext = enc_data[offset..];
    if (ciphertext.len != expected_size) {
        return error.CorruptedData;
    }

    const plain_buf = try allocator.alloc(u8, ciphertext.len);
    errdefer {
        std.crypto.secureZero(u8, plain_buf);
        allocator.free(plain_buf);
    }

    const ok = crypto.decrypt_aead(key, nonce, ciphertext, tag, plain_buf);
    if (!ok) {
        return error.DecryptionFailed;
    }

    return plain_buf;
}

pub fn free_model_memory(allocator: std.mem.Allocator, buffer: []u8) void {
    std.crypto.secureZero(u8, buffer);
    allocator.free(buffer);
}
