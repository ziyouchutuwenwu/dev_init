# zigler

## 说明

[关键文档](https://hexdocs.pm/zigler)

## 步骤

创建

```sh
mix new demo
```

mix.exs

```elixir
{:zigler, "~> 0.16", runtime: false}
```

```sh
mix deps.get
```

native/zig_demo/src/lib_root.zig

```zig
const std = @import("std");
const aa = @import("aa.zig");
const bb = @import("bb.zig");

pub fn demo1(list: []u8, output: []u8) []u8 {
    return aa.demo1(list, output);
}

pub fn demo2(list: []u8, output: []u8) []u8 {
    return bb.demo2(list, output);
}
```

native/zig_demo/src/aa.zig

```zig
pub fn demo1(list: []u8, output: []u8) []u8 {
    for (list, 0..) |v, i| {
        if (i >= output.len) break;
        output[i] = v * 2;
    }
    return output[0..list.len];
}
```

native/zig_demo/src/bb.zig

```zig
const std = @import("std");

pub fn demo2(list: []u8, data_list: []u8) []u8 {
    for (list, 0..data_list.len) |_, index| {
        data_list[index] = @truncate(index * 10);
    }
    return data_list[0..];
}
```

lib/demo_zig.ex

```elixir
defmodule DemoZig do
  @target System.get_env("ZIG_TARGET")

  use Zig,
    otp_app: :demo,
    leak_check: true,
    extra_modules: [
      # libroot 只是名字
      libroot: {"./native/zig_demo/src/lib_root.zig", []}
    ],
    # 交叉编译必需
    build_flags: if(@target, do: ["-Dtarget=#{@target}"], else: [])

  ~Z"""
  const beam = @import("beam");
  const libroot = @import("libroot");

  pub fn aaa(list: []u8) !beam.term {
    const allocator = beam.context.allocator;
    const data_list = try allocator.alloc(u8, list.len);
    defer allocator.free(data_list);
    const result = libroot.demo1(list, data_list);
    return beam.make(result, .{});
  }

  pub fn bbb(list: []u8) !beam.term {
    const allocator = beam.context.allocator;
    const data_list = try allocator.alloc(u8, list.len);
    defer allocator.free(data_list);
    const result = libroot.demo2(list, data_list);
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
    data_list = DemoZig.aaa([11, 22, 33, 44])
    Logger.debug("DemoZig.aaa #{inspect(data_list)}")
    data_list = DemoZig.bbb([11, 22, 33, 44])
    Logger.debug("DemoZig.bbb #{inspect(data_list)}")
  end
end
```

测试

```sh
# zig 在 PATH 里面
# 或者 ZIG_EXECUTABLE_PATH 指向 zig.exe
iex -S mix
```
