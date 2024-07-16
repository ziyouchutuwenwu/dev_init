# optional

## 例子

```zig
const std = @import("std");

pub fn main() !void {
    var demo_opt: ?u8 = null;

    demo_opt = 123;

    // 这是 capture 的写法
    if (demo_opt) |*value| {
        std.debug.print("data set\n", .{});
        value.* += 1;
    }

    if (demo_opt == null) {
        std.debug.print("null\n", .{});
    } else {
        const val = demo_opt.?;
        std.debug.print("not null, is {d}\n", .{val});
    }
}
```
