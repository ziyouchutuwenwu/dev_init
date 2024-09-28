# string

## 说明

zig 没有内置的 string 类型

## 例子

```zig
const std = @import("std");

const String = []const u8;

pub fn demo() String {
    return "aaa";
}

pub fn main() !void {
    const aa = demo();
    const bb = "bbb";
    std.log.debug("result {s} {s}", .{ aa, bb });
}
```
