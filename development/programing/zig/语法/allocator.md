# allocator

## 说明

建议把 allocator 当作为参数

## 用法

### page_allocator

很慢, 全局唯一，不需要 new

不推荐用

```zig
const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    const memory = allocator.alloc(u8, 100) catch |err| {
        std.debug.print("内存分配失败: {}\n", .{err});
        return;
    };
    defer allocator.free(memory);

    std.debug.print("分配成功, 长度: {}\n", .{memory.len});
}
```

### FixedBufferAllocator

不能使用堆内存的时候用，比如写内核的时候, 如果字节用完，会报 OutOfMemory 错误

不需要 deinit, alloc 出来的内存可以多次 free

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

### ArenaAllocator

用于短期内需要临时创建和销毁多个小对象

alloc 出来的内存会自动 free

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

### testing_allocator

用于测试用例里面检测 leak

```zig
const allocator = std.testing.allocator;
```

### DebugAllocator

调试用，deinit 返回状态值，用来检测内存泄漏

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

### smp_allocator

生产环境推荐，全局唯一，不需要 new

支持多线程，多核

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

## 最佳实践

debug 和 release 模式下自动选择分配器

mem.zig

```zig
const std = @import("std");
const builtin = @import("builtin");

pub const AppAllocator = struct {
    dbg: std.heap.DebugAllocator(.{}) = .{},

    pub fn get(self: *AppAllocator) std.mem.Allocator {
        return switch (builtin.mode) {
            .Debug, .ReleaseSafe => self.dbg.allocator(),
            .ReleaseFast, .ReleaseSmall => std.heap.smp_allocator,
        };
    }

    pub fn deinit(self: *AppAllocator) void {
        if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
            std.debug.assert(self.dbg.deinit() == .ok);
        }
    }
};
```

main.zig

```zig
const std = @import("std");
const mem = @import("mem.zig");

pub fn main(init: std.process.Init) !void {
    var app_allocator = mem.AppAllocator{};
    defer app_allocator.deinit();

    const allocator = app_allocator.get();
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    std.debug.print("分配成功, 长度: {}\n", .{memory.len});
}
```
