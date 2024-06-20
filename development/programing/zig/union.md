# union

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const Result = union(enum) { a: u8, b: f32, c: bool };

test "union" {
    var value = Result{ .b = 1.5 };
    value.b = 3;
    try expect(value.b == 3);
}
```
