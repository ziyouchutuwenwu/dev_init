# optional

## 说明

用于表示一个值可能存在或者为 null

## 例子

例子 1

```zig
const std = @import("std");

pub fn main() !void {
    // 创建 option
    var demo_option: ?u8 = null;
    demo_option = 111;

    // 修改 option
    if (demo_option) |*value| {
        std.log.debug("set data to option", .{});
        value.* += 1;
    }

    if (demo_option == null) {
        std.log.debug("null\n", .{});
    } else {
        const val = demo_option.?;
        std.log.debug("not null, is {d}", .{val});
    }
}
```

例子 2

```zig
const std = @import("std");

var _gpa: ?std.heap.GeneralPurposeAllocator(.{}) = null;

pub fn get_allocator() std.mem.Allocator {
    if (_gpa == null) {
        _gpa = std.heap.GeneralPurposeAllocator(.{}){};
    }

    return _gpa.?.allocator();
}

pub fn deinit() void {
    if (_gpa != null) {
        _ = _gpa.?.deinit();
        _gpa = null;
    }
}
```

```zig
const std = @import("std");
const gpa = @import("gpa.zig");

pub fn main() !void {
    const allocator = gpa.get_allocator();
    defer gpa.deinit();

    const formatted_str = try std.fmt.allocPrint(allocator, "测试 {}", .{42});
    defer allocator.free(formatted_str);

    std.debug.print("{s}\n", .{formatted_str});
}
```
