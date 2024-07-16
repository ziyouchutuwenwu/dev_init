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
{:zigler, "~> 0.10.2", runtime: false}
```

```sh
mix deps.get; mix zig.get
```

### 代码

lib/zig_src/bb.zig

```zig
const std = @import("std");
const print = @import("std").debug.print;

pub fn demo(list: []u8, dataList: []u8) []u8 {
    for (list) |_, index| {
        dataList[index] = @truncate(u8, index*10+5);
    }

    return dataList[0..];
}
```

lib/demo_zig.ex

```elixir
defmodule DemoZig do
  use Zig,
  otp_app: :demo,
  local_zig: true,
  leak_check: true

  ~Z"""
  const std = @import("std");
  const bb = @import("zig_src/bb.zig");
  const beam = @import("beam");

  pub fn aaa(env: beam.env, list: []u8) !beam.term {
      var dataList = try beam.allocator.alloc(u8, list.len);
      // defer beam.allocator.free(dataList);
      var result = bb.demo(list, dataList);
      return beam.make(env, result, .{});
  }
  """
end
```

lib/demo.ex

```elixir
defmodule Demo do
  def demo do
    data_list = DemoZig.aaa([11, 22, 33, 44])
    IO.inspect(data_list)
  end
end
```

test/nif_test.exs

```elixir
defmodule DemoTest do
  use ExUnit.Case

  test "nif leak check" do
    data_list = DemoZig.aaa([11, 22, 33, 44])
    assert data_list == <<5, 15, 25, 35>>
  end
end
```

### 单元测试

内存泄漏的检测，编译期测试不出来，可以通过单元测试

```sh
mix test test/nif_test.exs
```

### 运行

```sh
iex -S mix
```
