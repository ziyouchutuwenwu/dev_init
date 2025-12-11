# struct

## 例子

```zig
const std = @import("std");

const BaseStruct = struct {
    xx: f32,

    fn demo(self: *BaseStruct) void {
        std.log.debug("base demo xx = {}", .{self.xx});
    }
};

const DemoStruct = struct {
    base: BaseStruct,
    yy: f32,

    const Self = @This();

    fn demo1(self: *DemoStruct) void {
        std.log.debug("demo1 yy = {}", .{self.yy});
    }

    fn demo2(self: *Self) void {
        self.base.demo();
    }
};

pub fn main() !void {
    var aa = DemoStruct{
        .base = .{ .xx = 10 },
        .yy = 20,
    };

    aa.demo1();
    aa.demo2();
    std.log.debug("aa = {}", .{aa});
}
```
