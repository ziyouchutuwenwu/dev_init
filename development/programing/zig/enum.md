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
    try expect(@enumToInt(Result.aa) == 0);
    try expect(@enumToInt(Result.bb) == 1000);
    try expect(@enumToInt(Result.cc) == 1000000);
    try expect(@enumToInt(Result.dd) == 1000001);
}
```
