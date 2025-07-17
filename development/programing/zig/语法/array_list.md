# array_list

## 例子

```zig
const std = @import("std");
const equal = std.mem.eql;
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

pub fn main() !void {
    var array_list = ArrayList(u8).init(allocator);
    defer array_list.deinit();

    try array_list.append('H');
    try array_list.append('e');
    try array_list.append('l');
    try array_list.append('l');
    try array_list.append('o');
    try array_list.appendSlice(" World!");

    std.log.debug("{s}", .{array_list.items});
}
```
