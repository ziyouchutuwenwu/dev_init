# array

## 说明

array 固定大小

slice 动态大小

## 例子

### 结合 slice

```zig
const std = @import("std");

pub fn abc(list: []u8) void {
  std.debug.print("in abc {any}\n", .{list});
}

pub fn main() !void {
  var list = [_]u8{11, 22, 33, 44};
  abc(list[0..]);
}
```

### 实际例子

```zig
const std = @import("std");

const allocator = std.heap.page_allocator;

pub fn demo(list: []u8, dataList: []u8) []u8 {
    for (list) |_, index| {
        dataList[index] = @truncate(u8, index);
    }

    return dataList[0..];
}

pub fn main() void {
    var list = [_]u8{ 11, 22, 33, 44 };
    const dataList = allocator.alloc(u8, list.len) catch | err|{
        std.log.debug("err {any}", .{err});
        return;
    };

    defer allocator.free(dataList);
    var aa = demo(list[0..], dataList);
    std.debug.print("result {any}\n", .{aa});
}
```
