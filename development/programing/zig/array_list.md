# array_list

## 例子

```zig
const std = @import("std");
const expect = std.testing.expect;

const equal = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arrayList" {
    var array_list = ArrayList(u8).init(test_allocator);
    defer arrayList.deinit();

    try array_list.append('H');
    try array_list.append('e');
    try array_list.append('l');
    try array_list.append('l');
    try array_list.append('o');
    try array_list.appendSlice(" World!");

    try expect(equal(u8, array_list.items, "Hello World!"));
}
```
