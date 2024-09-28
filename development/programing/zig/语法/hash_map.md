# hash_map

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const allocator = std.testing.allocator;

test "hash_map" {
    const Point = struct { x: i32, y: i32 };

    var hash_map = std.AutoHashMap(u32, Point).init(
        allocator,
    );
    defer hash_map.deinit();

    try hash_map.put(1525, .{ .x = 1, .y = -4 });
    try hash_map.put(1550, .{ .x = 2, .y = -3 });
    try hash_map.put(1575, .{ .x = 3, .y = -2 });
    try hash_map.put(1600, .{ .x = 4, .y = -1 });

    try expect(hash_map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = hash_map.iterator();

    while (iterator.next()) |item| {
        std.log.debug("key {d}, x {d}, y {d}", .{ item.key_ptr.*, item.value_ptr.x, item.value_ptr.y });
        sum.x += item.value_ptr.x;
        sum.y += item.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
}
```
