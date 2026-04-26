# optional

## 说明

用于表示一个值可能存在或者为 null

## 例子

```zig
const std = @import("std");

pub fn main() !void {
    // 创建 option
    var demo_option: ?u8 = null;
    demo_option = 111;

    // 修改 option
    if (demo_option) |*value| {
        std.log.debug("set data to option", .{});
        value.* += 1;
    }

    if (demo_option == null) {
        std.log.debug("null\n", .{});
    } else {
        const val = demo_option.?;
        std.log.debug("not null, is {d}", .{val});
    }
}
```
