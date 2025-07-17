# union

## 例子

```zig
const std = @import("std");

const Result = union(enum) {
    a: u8,
    b: f32,
    c: bool,
};

pub fn main() !void {
    var value = Result{
        .b = 1.5,
    };
    value.b = 3.156;
    std.log.debug("{d:.2}", .{value.b});
}
```
