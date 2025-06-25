# log

## 例子

run 模式

```zig
const std = @import("std");

pub fn main() void {
    const info = "hi";
    const data_list = [_]u8{ 11, 22, 33, 44, 55 };
    std.log.debug("info {s} data_list {any}", .{ info, data_list });
}
```

test 不支持 log

```zig
const std = @import("std");

test "debug log" {
    // std.log.debug("log.debug", .{});
    std.debug.print("debug.print\n", .{});
}
```
