pub const hwid = @import("hwid.zig");
pub const license = @import("license.zig");
pub const model = @import("model.zig");
pub const label = @import("label.zig");

comptime {
    _ = hwid;
    _ = license;
    _ = model;
    _ = label;
}
