# dirty_cpu

## 说明

防止 nif 占用太长时间 cpu。

大白话解释，当多个进程同时访问 nif 时，如果 nif 是很耗时的操作，以死循环为例，不加 dirty 描述，则会卡死在 1 个 cpu 上，其它 cpu 空转，加了以后，则会在多个 cpu 上满载

## 例子

```elixir
defmodule MyDemo do
  use Zig,
    otp_app: :demo,
    nifs: [
      aaa: [:dirty_cpu]
    ]

  ~Z"""
  pub fn aaa(value1: u8, value2: u8) u8 {
    return value1 + value2;
  }
  """
end
```

测试

```sh
# 参见 erlang 调度器
iex --erl "+S 4" -S mix

# 或者
export ERL_FLAGS="+S 7"
iex -S mix
```
