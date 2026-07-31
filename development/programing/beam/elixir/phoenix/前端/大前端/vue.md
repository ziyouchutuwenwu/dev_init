# vue

## 说明

## 步骤

assets 下

```sh
npm create vue
```

vite.config.ts

```sh
# .......
build: {
  outDir: "../../priv/static/bbb",
  emptyOutDir: true,
},
```

package.json

scripts 下

```sh
"watch": "vite build --watch",
```

lib/web_demo_web.ex

```elixir
def static_paths, do: ~w(
  bbb
  ......
)
```

页面 layout

lib/web_demo_web/components/layouts/vue.html.heex

参考 vue 编译后的 index.html

```html
<!DOCTYPE html>
<html lang="">
  <head>
    <meta name="csrf-token" content="{get_csrf_token()}" />

    <meta charset="UTF-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Vite App</title>
    <script type="module" crossorigin src="/bbb/assets/index-SQQ-9-xo.js"></script>
    <link rel="stylesheet" crossorigin href="bbb/assets/index-DEm2-gV0.css" />
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

router.ex

```elixir
# phoenix 处理
scope "/api", WebDemoWeb do
  pipe_through :api
  # ...
end

# 前端都给 vue
scope "/", WebDemoWeb do
  pipe_through :browser
  get "/*path", PageController, :home
end
```

page_controller.ex

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: {WebDemoWeb.Layouts, :vue})
  end
end
```

或者

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :put_layout, html: {WebDemoWeb.Layouts, :vue}

  def home(conn, _params) do
    render(conn, :home)
  end
end
```

mix.exs

```elixir
defp aliases do
  [
    "assets.deploy": [
      "cmd -- npm run build --prefix assets/aaa",
      # ......
    ]
  ]
end
```

验证

```sh
mix phx.server
```
