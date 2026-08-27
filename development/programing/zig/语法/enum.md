# enum

## 例子

```zig
const std = @import("std");

const Result = enum(u32) {
    aa,
    bb = 1000,
    cc = 1000000,
    dd,
};

pub fn main() void {
    std.debug.print("aa: {}\n", .{@intFromEnum(Result.aa)});
    std.debug.print("bb: {}\n", .{@intFromEnum(Result.bb)});
    std.debug.print("cc: {}\n", .{@intFromEnum(Result.cc)});
    std.debug.print("dd: {}\n", .{@intFromEnum(Result.dd)});
}
```
