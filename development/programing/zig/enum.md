# enum

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const Result = enum(u32) {
    aa,
    bb = 1000,
    cc = 1000000,
    dd,
};

test "set enum ordinal value" {
    try expect(@intFromEnum(Result.aa) == 0);
    try expect(@intFromEnum(Result.bb) == 1000);
    try expect(@intFromEnum(Result.cc) == 1000000);
    try expect(@intFromEnum(Result.dd) == 1000001);
}
```
