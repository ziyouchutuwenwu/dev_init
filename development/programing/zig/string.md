# string

## 说明

zig 没有内置的 string 类型

## 例子

```zig
const std = @import("std");

const string = []const u8;

pub fn demo() string {
    return "string in demo";
}

pub fn main() !void {
    const aa = demo();
    var bb = "bb";
    std.debug.print("result {*}. {s}\n", .{aa, bb});
}
```
