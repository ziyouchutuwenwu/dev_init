# DebugAllocator

## 说明

调试用，deinit 返回状态值，用来检测内存泄漏

## 用法

```zig
const std = @import("std");

pub fn main() void {
    var da = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(da.deinit() == .ok);
    const allocator = da.allocator();

    const memory = allocator.alloc(u8, 100) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    defer allocator.free(memory);

    std.debug.print("分配成功, 长度: {}\n", .{memory.len});
}
```
