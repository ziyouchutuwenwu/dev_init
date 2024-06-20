# struct

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const MyStruct = struct {
     x: f32,
     y: f32,
     z: f32 = 222.0,

     fn demo(self: *MyStruct) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "struct usage" {
    var aa = MyStruct{
        .x = 10,
        .y = 20,
    };
    aa.demo();
    try expect(aa.x == 20);
    try expect(aa.y == 10);
}
```
