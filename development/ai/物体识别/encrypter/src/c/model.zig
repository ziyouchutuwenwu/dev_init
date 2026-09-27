const std = @import("std");
const base = @import("base");
const crypto = base.crypto;
const model = base.model;

const c_allocator = std.heap.c_allocator;

export fn decrypt_model(
    enc_path: ?[*:0]const u8,
    out_ptr: ?*[*]u8,
    out_len: ?*usize,
) c_int {
    const path = enc_path orelse return -1;
    const p_ptr = out_ptr orelse return -1;
    const p_len = out_len orelse return -1;
    const path_slice = std.mem.sliceTo(path, 0);

    const plain = model.decrypt_model_to_memory_default(c_allocator, path_slice) catch {
        p_len.* = 0;
        return -1;
    };
    p_ptr.* = plain.ptr;
    p_len.* = plain.len;
    return 0;
}

export fn get_model_id(
    enc_path: ?[*:0]const u8,
    out_buf: ?[*]u8,
    max_len: usize,
) c_int {
    const path = enc_path orelse return -1;
    const buf = out_buf orelse return -1;
    const path_slice = std.mem.sliceTo(path, 0);
    const mid = model.read_model_id_from_file(path_slice) catch return -1;
    var hex: [model.MODEL_ID_LEN * 2]u8 = undefined;
    _ = crypto.bytes_to_hex(&mid, &hex);
    if (max_len <= hex.len) return -2;
    @memcpy(buf[0..hex.len], &hex);
    buf[hex.len] = 0;
    return @as(c_int, @intCast(hex.len));
}

export fn free_model_memory(ptr: ?[*]u8, len: usize) void {
    if (len == 0) return;
    const p = ptr orelse return;
    const slice = p[0..len];
    model.free_model_memory(c_allocator, slice);
}
