# leak

## 说明

leak 检测

## 步骤

native/zig_demo/src/xx.zig

```zig
const std = @import("std");

pub fn demo(list: []u8, data_list: []u8) []u8 {
    for (list, 0..data_list.len) |_, index| {
        data_list[index] = @truncate(index * 10);
    }

    return data_list[0..];
}
```

lib/demo_zig.ex

```elixir
defmodule DemoZig do
  use Zig,
    otp_app: :demo,
    leak_check: true,
    extra_modules: [
      bb: {"./native/zig_demo/src/xx.zig", []}
    ]

  ~Z"""
  const beam = @import("beam");
  const bb = @import("bb");

  pub fn demo(list: []u8) !beam.term {
    const allocator = beam.context.allocator;
    const data_list = try allocator.alloc(u8, list.len);
    defer allocator.free(data_list);
    const result = bb.demo(list, data_list);
    return beam.make(result, .{});
  }
  """
end
```

lib/demo.ex

```elixir
defmodule Demo do
  require Logger
  def demo do
    data_list = DemoZig.demo([11, 22, 33, 44])
    Logger.debug("#{inspect(data_list)}")
  end
end
```
