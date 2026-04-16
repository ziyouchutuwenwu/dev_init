# escript

## 说明

可执行脚本，需要本机安装 elixir

## 例子

```sh
mix new demo
```

mix.exs

```elixir
def project do
  [
    ...
    escript: escript()
  ]
end

defp escript do
  [
    main_module: DemoApp,
    path: "_build/escripts/aaa",
  ]
end
```

```elixir
defmodule DemoApp do
  require Logger
  def main(args) do
    Logger.debug("args #{inspect(args)}")
  end
end
```

发布

```sh
mix escript.build
```
