# application

## 例子

```elixir
defmodule DemoApp do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("in app start")
    {:ok, self()}
  end
end
```

mix.exs

```elixir
def application do
  [
    mod: {DemoApp, []},
  ]
end
```
