# json

## 说明

标准库里面, 需要先定义 struct, 比较挫

## 例子

```zig
const std = @import("std");

const Place = struct { lat: f32, long: f32 };

fn str_to_json(allocator: std.mem.Allocator, json_str: []u8) !Place {
    const parsed = try std.json.parseFromSlice(
        Place,
        allocator,
        json_str,
        .{},
    );
    defer parsed.deinit();

    const place = parsed.value;
    return place;
}

fn json_to_str(allocator: std.mem.Allocator, json_obj: Place) ![]u8 {
    var json_str = std.ArrayList(u8).init(allocator);
    try std.json.stringify(json_obj, .{}, json_str.writer());

    std.log.debug("{s}", .{json_str.items});

    return json_str.items;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const obj = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };
    const json_str = try json_to_str(allocator, obj);
    const json_obj = try str_to_json(allocator, json_str);
    std.log.debug("{any}", .{json_obj.long});
}
```
