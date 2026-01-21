# array

## 说明

array 固定大小

slice 动态大小

## 例子

### 结合 slice

```zig
const std = @import("std");

pub fn abc(list: []u8) void {
    std.log.debug("in abc {any}", .{list});
}

pub fn main() !void {
    var list = [_]u8{ 11, 22, 33, 44 };
    abc(list[0..]);
}
```

### 实际例子

```zig
const std = @import("std");

const allocator = std.heap.page_allocator;

pub fn demo(list: []u8, data_list: []u8) []u8 {
    for (list, 0..list.len) |_, index| {
        data_list[index] = @truncate(index);
    }

    return data_list[0..];
}

pub fn main() void {
    var list = [_]u8{ 11, 22, 33, 44 };
    const data_list = allocator.alloc(u8, list.len) catch |err| {
        std.log.debug("err {any}", .{err});
        return;
    };

    defer allocator.free(data_list);
    const aa = demo(list[0..], data_list);
    std.log.debug("result {any}", .{aa});
}
```
