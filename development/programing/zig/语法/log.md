# log

## 说明

| 输出方式        | 输出位置            |
| --------------- | ------------------- |
| std.debug.print | 测试模式，到 stderr |
| std.log.debug   | run 模式            |

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

```zig
const std = @import("std");

test "debug log" {
    // std.log.debug("log.debug", .{});
    std.debug.print("debug.print\n", .{});
}
```
