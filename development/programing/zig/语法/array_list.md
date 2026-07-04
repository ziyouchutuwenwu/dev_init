# array_list

## 例子

```zig
const std = @import("std");

const ArrayList = std.ArrayListUnmanaged;
const allocator = std.heap.page_allocator;

pub fn main() !void {
    var array_list = ArrayList(u8){ .items = &.{}, .capacity = 0 };
    defer array_list.deinit(allocator);

    try array_list.append(allocator, 'H');
    try array_list.append(allocator, 'e');
    try array_list.append(allocator, 'l');
    try array_list.append(allocator, 'l');
    try array_list.append(allocator, 'o');
    try array_list.appendSlice(allocator, " World!");

    std.log.debug("{s}", .{array_list.items});
}
```
