# escript

## 说明

生成可执行文件

运行时，需要安装 elixir

## 例子

```sh
mix new demo
```

mix.exs

```elixir
def project do
  [
    ...
    escript: escript(),
  ]
end

defp escript do
  [
    main_module: DemoApp,
    # 生成的可执行文件名
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
