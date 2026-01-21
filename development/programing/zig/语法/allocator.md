# allocator

## 说明

建议把 allocator 当作为参数，类型是 std.mem.Allocator

## 用法

### page_allocator

通常用于处理大块内存的分配, 很慢, 不需要 deinit

```zig
const std = @import("std");
const expect = std.testing.expect;

test "page allocator" {
    const allocator = std.heap.page_allocator;

    const memory = demo(allocator) catch |err| {
        std.debug.print("error occurred: {}\n", .{err});
        return;
    };

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

pub fn demo(allocator: std.mem.Allocator) ![]u8 {
    const memory = try allocator.alloc(u8, 100);

    defer {
        std.debug.print("准备 free allocator\n", .{});
        allocator.free(memory);
    }

    return memory;
}
```

### fba

不能使用堆内存的时候用，比如写内核的时候, 如果字节用完，会报 OutOfMemory 错误

不需要 deinit, alloc 出来的内存可以多次 free

```zig
const std = @import("std");
const expect = std.testing.expect;

test "fba" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = demo(allocator) catch |err| {
        std.log.debug("error occurred: {}", .{err});
        return;
    };

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

pub fn demo(allocator: std.mem.Allocator) ![]u8 {
    const memory = try allocator.alloc(u8, 100);

    defer {
        std.debug.print("准备 free allocator\n", .{});
        allocator.free(memory);
    }

    return memory;
}
```

### gpa

为安全设计的内存分配器

deinit 返回状态值，用来检测内存泄漏

```zig
const std = @import("std");
const expect = std.testing.expect;

test "gpa" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() != .ok) {
            @panic("发现内存泄漏");
        }
    }

    const allocator = gpa.allocator();

    const memory = demo(allocator) catch |err| {
        std.log.debug("error occurred: {}", .{err});
        return;
    };

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

pub fn demo(allocator: std.mem.Allocator) ![]u8 {
    const memory = try allocator.alloc(u8, 100);

    defer {
        std.debug.print("准备 free allocator\n", .{});
        allocator.free(memory);
    }

    return memory;
}
```

### testing_allocator

用于测试用例里面检测 leak

运行 `zig test xxx.zig` 的时候才能用

```zig
const allocator = std.testing.allocator;
```

### ArenaAllocator

用于短期内需要临时创建和销毁多个小对象

alloc 出来的内存会自动 free

```zig
const std = @import("std");

test "arena" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer {
        std.debug.print("准备 arena Allocator.deinit\n", .{});
        arena.deinit();
    }

    const allocator = arena.allocator();

    const m1 = try allocator.alloc(u8, 1);
    const m2 = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);

    defer {
        std.debug.print("准备 free arena Allocator\n", .{});
        allocator.free(m1);
        allocator.free(m2);
        // allocator.free(m3);
    }
}
```

## 封装

safe_gpa.zig

```zig
const std = @import("std");

pub const Gpa = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}),

    pub fn init() Gpa {
        return .{ .gpa = .{} };
    }

    pub fn allocator(self: *Gpa) std.mem.Allocator {
        return self.gpa.allocator();
    }

    pub fn deinit(self: *Gpa) void {
        const result = self.gpa.deinit();
        if (result != .ok) {
            std.log.err("内存泄漏！", .{});
        }
    }
};

pub fn init() Gpa {
    return Gpa.init();
}
```

tsa.zig

```zig
const std = @import("std");

pub const ThreadSafeAllocator = struct {
    tsa: std.heap.ThreadSafeAllocator,

    pub fn init(child_allocator: std.mem.Allocator) ThreadSafeAllocator {
        return .{
            .tsa = .{ .child_allocator = child_allocator },
        };
    }

    pub fn allocator(self: *ThreadSafeAllocator) std.mem.Allocator {
        return self.tsa.allocator();
    }
};
```

arena.zig

```zig
const std = @import("std");

pub const Arena = struct {
    arena: std.heap.ArenaAllocator,

    pub fn init(child_allocator: std.mem.Allocator) Arena {
        return .{
            .arena = std.heap.ArenaAllocator.init(child_allocator),
        };
    }

    pub fn allocator(self: *Arena) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn deinit(self: *Arena) void {
        self.arena.deinit();
    }
};
```

main.zig

```zig
const std = @import("std");

const arena = @import("arena.zig");
const safe_gpa = @import("safe_gpa.zig");
const tsa = @import("tsa.zig");

pub fn main() !void {
    var gpa = safe_gpa.init();
    defer gpa.deinit();

    const gpa_allocator = gpa.allocator();

    // 线程安全分配器
    var ts = tsa.ThreadSafeAllocator.init(gpa_allocator);
    const tsa_allocator = ts.allocator();

    // Arena 分配器
    var ar = arena.Arena.init(tsa_allocator);
    defer ar.deinit();
    const allocator = ar.allocator();

    const formatted_str = try std.fmt.allocPrint(allocator, "测试 {}", .{42});
    std.log.debug("{s}", .{formatted_str});
}
```
