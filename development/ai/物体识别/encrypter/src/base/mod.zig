pub const crypto = @import("crypto.zig");
pub const hwid = @import("hwid.zig");
pub const license = @import("license.zig");
pub const model = @import("model.zig");
pub const duration = @import("duration.zig");

comptime {
    _ = crypto;
    _ = hwid;
    _ = license;
    _ = model;
    _ = duration;
}
