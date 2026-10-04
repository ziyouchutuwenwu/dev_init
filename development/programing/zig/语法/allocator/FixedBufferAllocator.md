# FixedBufferAllocator

## 说明

不能使用堆内存的时候用，比如写内核的时候, 如果字节用完，会报 OutOfMemory 错误

## 用法

```zig
const std = @import("std");

pub fn main() void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = allocator.alloc(u8, 100) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    defer allocator.free(memory);

    std.debug.print("分配成功, 长度: {}\n", .{memory.len});
}
```
