# case

## 说明

guard 跟在 when 后面

## 例子

```elixir
defmodule Demo do
  def demo(x) do
    case x do
      s when is_binary(s) -> "字符串: #{s}"
      n when is_integer(n) -> "整数: #{n}"
      _ -> "其他类型"
    end
  end
end
```

测试

```elixir
Demo.demo(10)
Demo.demo("abc")
```
