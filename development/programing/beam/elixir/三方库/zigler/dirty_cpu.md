# dirty_cpu

防止 nif 占用太长时间 cpu

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
