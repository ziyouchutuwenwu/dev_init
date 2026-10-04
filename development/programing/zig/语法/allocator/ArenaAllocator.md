# ArenaAllocator

## 说明

用于短期内需要临时创建和销毁多个小对象

alloc 出来的内存会自动 free

## 用法

```zig
const std = @import("std");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const m1 = allocator.alloc(u8, 1) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    const m2 = allocator.alloc(u8, 10) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    _ = allocator.alloc(u8, 100) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };

    std.debug.print("分配成功: m1={}, m2={}\n", .{ m1.len, m2.len });
}
```
