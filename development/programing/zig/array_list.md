# array_list

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const equal = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arrayList" {
    var arrayList = ArrayList(u8).init(test_allocator);
    defer arrayList.deinit();

    try arrayList.append('H');
    try arrayList.append('e');
    try arrayList.append('l');
    try arrayList.append('l');
    try arrayList.append('o');
    try arrayList.appendSlice(" World!");

    try expect(equal(u8, arrayList.items, "Hello World!"));
}
```
