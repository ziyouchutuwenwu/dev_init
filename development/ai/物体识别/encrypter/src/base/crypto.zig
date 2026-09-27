const std = @import("std");

pub const Ed25519 = std.crypto.sign.Ed25519;
pub const ChaCha20Poly1305 = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
pub const Sha256 = std.crypto.hash.sha2.Sha256;

pub const KEY_LEN: usize = 32;
pub const PUBKEY_LEN: usize = 32;
pub const SIG_LEN: usize = 64;
pub const NONCE_LEN: usize = 12;
pub const TAG_LEN: usize = 16;

pub const DEFAULT_MODEL_KEY: [KEY_LEN]u8 = [32]u8{
    0x39, 0x7a, 0xf1, 0x8c, 0xd2, 0x4e, 0x9b, 0x15,
    0x63, 0xa8, 0x50, 0xe7, 0x24, 0xbd, 0xc1, 0x6e,
    0x8f, 0x32, 0x9a, 0x5b, 0x47, 0xd8, 0x19, 0xce,
    0x72, 0x60, 0xb3, 0xe4, 0x95, 0x1f, 0x0a, 0x82,
};

pub const DEFAULT_LICENSE_SEED: [KEY_LEN]u8 = [32]u8{
    0x91, 0x5e, 0x3a, 0x7c, 0x2b, 0xd8, 0x40, 0x19,
    0xa6, 0xc4, 0x8f, 0x03, 0x72, 0xb5, 0x61, 0xde,
    0x14, 0x98, 0xc7, 0x3f, 0x82, 0x5a, 0x60, 0xeb,
    0x4d, 0x21, 0xe7, 0x90, 0x38, 0xb9, 0x5c, 0x16,
};
pub const DEFAULT_LICENSE_PUBKEY: [PUBKEY_LEN]u8 = [32]u8{
    0xbe, 0xe3, 0x69, 0xe3, 0xec, 0xd7, 0x40, 0x2a,
    0xc7, 0x96, 0x4f, 0xd3, 0x9d, 0x08, 0xd1, 0x22,
    0xc8, 0xfa, 0x74, 0xc4, 0x3c, 0x4c, 0xb5, 0x58,
    0x1d, 0x0f, 0x27, 0xee, 0x57, 0x30, 0x77, 0xd0,
};

pub fn random_bytes(buf: []u8) void {
    std.crypto.random.bytes(buf);
}

pub fn generate_key_pair(seed: [KEY_LEN]u8) !Ed25519.KeyPair {
    return Ed25519.KeyPair.generateDeterministic(seed);
}

pub fn sign_message(key_pair: Ed25519.KeyPair, msg: []const u8) ![SIG_LEN]u8 {
    const sig = try key_pair.sign(msg, null);
    return sig.toBytes();
}

pub fn verify_signature(sig_bytes: [SIG_LEN]u8, pubkey_bytes: [PUBKEY_LEN]u8, msg: []const u8) bool {
    const pubkey = Ed25519.PublicKey.fromBytes(pubkey_bytes) catch return false;
    const sig = Ed25519.Signature.fromBytes(sig_bytes);
    sig.verify(msg, pubkey) catch return false;
    return true;
}

pub fn encrypt_aead(
    key: [KEY_LEN]u8,
    nonce: [NONCE_LEN]u8,
    plaintext: []const u8,
    out_ciphertext: []u8,
    out_tag: *[TAG_LEN]u8,
) void {
    ChaCha20Poly1305.encrypt(out_ciphertext, out_tag, plaintext, "", nonce, key);
}

pub fn decrypt_aead(
    key: [KEY_LEN]u8,
    nonce: [NONCE_LEN]u8,
    ciphertext: []const u8,
    tag: [TAG_LEN]u8,
    out_plaintext: []u8,
) bool {
    ChaCha20Poly1305.decrypt(out_plaintext, ciphertext, tag, "", nonce, key) catch return false;
    return true;
}

pub fn hash_sha256(data: []const u8) [32]u8 {
    var out: [32]u8 = undefined;
    Sha256.hash(data, &out, .{});
    return out;
}

pub fn hex_to_bytes(hex: []const u8, out: []u8) bool {
    if (hex.len != out.len * 2) return false;
    var i: usize = 0;
    while (i < out.len) : (i += 1) {
        const h = hex_char_to_val(hex[i * 2]) orelse return false;
        const l = hex_char_to_val(hex[i * 2 + 1]) orelse return false;
        out[i] = (@as(u8, @intCast(h)) << 4) | @as(u8, @intCast(l));
    }
    return true;
}

pub fn bytes_to_hex(bytes: []const u8, out: []u8) bool {
    if (out.len < bytes.len * 2) return false;
    const hex_digits = "0123456789abcdef";
    for (bytes, 0..) |b, i| {
        out[i * 2] = hex_digits[b >> 4];
        out[i * 2 + 1] = hex_digits[b & 0x0f];
    }
    return true;
}

fn hex_char_to_val(c: u8) ?u4 {
    return switch (c) {
        '0'...'9' => @intCast(c - '0'),
        'a'...'f' => @intCast(c - 'a' + 10),
        'A'...'F' => @intCast(c - 'A' + 10),
        else => null,
    };
}
