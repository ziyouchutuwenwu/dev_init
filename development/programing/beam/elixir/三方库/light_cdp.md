# light_cdp

## 说明

结合 lightpanda 的 html 解析，支持 js

## 例子

启动 lightpanda

```sh
lightpanda serve --host 127.0.0.1 --port 9222
```

依赖

```elixir
defp deps do
  [
    {:light_cdp, github: "lessless/light_cdp"}
  ]
end
```

代码

```elixir
defmodule Demo do
  require Logger

  def demo do
    {:ok, session} = LightCDP.start(host: "127.0.0.1", port: 9222)
    {:ok, page} = LightCDP.new_page(session)

    :ok = LightCDP.Page.navigate(page, "https://www.baidu.com")
    {:ok, html} = LightCDP.Page.content(page)
    Logger.debug(inspect(html))

    LightCDP.stop(session)
  end
end
```
