# hash_map

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const allocator = std.testing.allocator;

test "hash_map" {
    const Point = struct { x: i32, y: i32 };

    var hashMap = std.AutoHashMap(u32, Point).init(
        allocator,
    );
    defer hashMap.deinit();

    try hashMap.put(1525, .{ .x = 1, .y = -4 });
    try hashMap.put(1550, .{ .x = 2, .y = -3 });
    try hashMap.put(1575, .{ .x = 3, .y = -2 });
    try hashMap.put(1600, .{ .x = 4, .y = -1 });

    try expect(hashMap.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = hashMap.iterator();

    while (iterator.next()) |item| {
        std.debug.print("key {d}, x {d}, y {d}\n", .{ item.key_ptr.*, item.value_ptr.x, item.value_ptr.y });
        sum.x += item.value_ptr.x;
        sum.y += item.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
}
```
