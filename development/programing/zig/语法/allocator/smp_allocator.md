# smp_allocator

## 说明

生产环境推荐，全局唯一，不需要 new

支持多线程，多核

## 用法

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const memory = allocator.alloc(u8, 100) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    defer allocator.free(memory);

    std.debug.print("分配成功, 长度: {}\n", .{memory.len});
}
```
