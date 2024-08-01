# guard

主要用于缩短代码，否则在方法内用模式匹配，会生成很长的面条代码

## 例子

和 erlang 不同，支持自定义 guard

```elixir
defmodule DemoGuard do
  defguard is_even(value) when is_integer(value) and rem(value, 2) == 0
end

defmodule Demo do
  import DemoGuard

  def aaa(n) when n > 0, do: bbb(n, 0)

  defp bbb(1, count) do
    count
  end

  defp bbb(n, count) when is_even(n) do
    bbb(div(n, 2), count + 1)
  end

  defp bbb(n, count) do
    bbb(3 * n + 1, count + 1)
  end
end
```
