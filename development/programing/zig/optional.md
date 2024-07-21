# optional

## 例子

```zig
const std = @import("std");

pub fn main() !void {
    // 要么是 u8 类型的值，要么是 null
    var demo_option: ?u8 = null;
    demo_option = 111;

    // 修改 option
    if (demo_option) |*value| {
        std.debug.print("set data to option\n", .{});
        value.* += 1;
    }

    if (demo_option == null) {
        std.debug.print("null\n", .{});
    } else {
        const val = demo_option.?;
        std.debug.print("not null, is {d}\n", .{val});
    }
}
```
