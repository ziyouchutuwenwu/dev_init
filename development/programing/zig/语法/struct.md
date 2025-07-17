# struct

## 例子

```zig
const std = @import("std");

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

pub fn main() !void {
    var aa = MyStruct{
        .x = 10,
        .y = 20,
    };
    aa.demo();
    std.log.debug("aa = {}", .{aa});
}
```
