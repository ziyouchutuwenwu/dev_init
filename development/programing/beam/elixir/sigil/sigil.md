# sigil

## 自定义

```elixir
defmodule DemoSigil do
  def sigil_x(string, []), do: String.upcase(string)
end
import DemoSigil
```

测试

```elixir
~x/zzzzzzzzzzz/
```
