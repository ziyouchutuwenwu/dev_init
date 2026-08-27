# 调用 c

## 例子

native/c_demo/include/increment.h

```h
int add_one(int value);
```

native/c_demo/src/increment.c

```c
int add_one(int value) {
    return value + 1;
}
```

lib/demo_c.ex

```elixir
defmodule DemoC do
  use Zig,
    otp_app: :demo,
    c: [
      include_dirs: ["../native/c_demo/include"],
      src: ["../native/c_demo/src/increment.c"]
    ]

  ~Z"""
  pub extern fn add_one(value: c_int) c_int;
  """
end
```
