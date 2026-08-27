# hash_map

## 例子

```zig
const std = @import("std");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const Point = struct { x: i32, y: i32 };

    var hash_map = std.AutoHashMap(u32, Point).init(allocator);
    defer hash_map.deinit();

    hash_map.put(1525, .{ .x = 1, .y = -4 }) catch @panic("put failed");
    hash_map.put(1550, .{ .x = 2, .y = -3 }) catch @panic("put failed");
    hash_map.put(1575, .{ .x = 3, .y = -2 }) catch @panic("put failed");
    hash_map.put(1600, .{ .x = 4, .y = -1 }) catch @panic("put failed");

    if (hash_map.count() != 4) @panic("count != 4");

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = hash_map.iterator();

    while (iterator.next()) |item| {
        std.log.debug("key {d}, x {d}, y {d}", .{ item.key_ptr.*, item.value_ptr.x, item.value_ptr.y });
        sum.x += item.value_ptr.x;
        sum.y += item.value_ptr.y;
    }

    if (sum.x != 10) @panic("sum.x != 10");
    if (sum.y != -10) @panic("sum.y != -10");
}
```
