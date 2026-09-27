# exgbk

## 说明

gbk 转 utf8

## 用法

注意，要用这个路径下的

```elixir
{:exgbk, git: "https://github.com/guidao/exgbk"}
```

```elixir
defmodule Demo do
  def demo do
    data_bin = <<197, 183, 195, 203, 180, 211, 182, 237, 189, 248, 191, 218, 210, 186, 187, 175, 204, 236, 200, 187, 198, 248, 180, 180, 188, 205, 194, 188>>
    ExGBK.to_utf8(data_bin)
  end
end
```
