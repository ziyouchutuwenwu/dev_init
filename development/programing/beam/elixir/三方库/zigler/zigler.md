# zigler

## 说明

[关键文档](https://hexdocs.pm/zigler/beam.html)

## 步骤

### 创建项目

```sh
mix new demo
```

### 添加依赖

mix.exs

```elixir
{:zigler, "~> 0.16", runtime: false}
```

```sh
mix deps.get
```

### 代码

lib/native/zigler/src/bb.zig

```zig
const std = @import("std");

pub fn demo(list: []u8, data_list: []u8) []u8 {
    for (list, 0..data_list.len) |_, index| {
        data_list[index] = @truncate(index * 10);
    }

    return data_list[0..];
}
```

lib/native/demo_zig.zig

```zig
const std = @import("std");
const beam = @import("beam");
const bb = @import("zigler/src/bb.zig");

pub fn aaa(list: []u8) !beam.term {
    const allocator = beam.context.allocator;

    const data_list = try allocator.alloc(u8, list.len);
    defer allocator.free(data_list);

    const result = bb.demo(list, data_list);

    return beam.make(result, .{});
}
```

lib/native/demo_zig.ex

```elixir
defmodule DemoZig do
  use Zig,
    otp_app: :demo,
    leak_check: true,
    zig_code_path: "demo_zig.zig"
end
```

lib/demo.ex

```elixir
defmodule Demo do
  require Logger
  def demo do
    data_list = DemoZig.aaa([11, 22, 33, 44])
    Logger.debug("#{inspect(data_list)}")
  end
end
```

test/demo_test.exs

```elixir
defmodule DemoTest do
  use ExUnit.Case, async: true

  test "nif leak check" do
    data_list = DemoZig.aaa([11, 22, 33, 44])
    assert data_list == <<0, 10, 20, 30>>
  end
end
```

### 测试

```sh
# zig 在 PATH 里面，或者 ZIG_EXECUTABLE_PATH 指向 zig.exe
mix test test/demo_test.exs
iex -S mix
```
