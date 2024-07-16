# application 例子

## 代码

```elixir
defmodule HelloworldApp do
  use Application

  def start(_type, _args) do
    IO.puts "aaa"
    {:ok, self()}
  end
end
```

mix.exs

```elixir
def application do
  [
    mod: {HelloworldApp, []},
  ]
end
```
