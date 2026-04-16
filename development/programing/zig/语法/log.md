# log

## 说明

| 分类            | 说明                                |
| --------------- | ----------------------------------- |
| std.debug.print | 任何情况下都会输出                  |
| std.log.debug   | 遵循 log 级别，release 的时候不输出 |

## 例子

```zig
const std = @import("std");

pub fn main() void {
    const data_list = [_]u8{ 11, 22, 33, 44, 55 };
    std.debug.print("data {any}\n", .{ data_list });
    // std.log.debug("data {any}", .{ data_list });
}
```
