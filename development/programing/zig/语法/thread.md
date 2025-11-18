# thread

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

fn threadProc(thread_arg: u32) void {
    std.log.debug("{d} in thread", .{thread_arg});
}

pub fn main() !void {
    const thread = try std.Thread.spawn(.{}, threadProc, .{11111});
    // _ = thread;
    thread.join();
}
```
