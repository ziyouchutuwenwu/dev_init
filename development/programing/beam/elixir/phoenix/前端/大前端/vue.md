# vue

## 说明

js 动态渲染

## 步骤

assets 下

```sh
# 创建项目 aaa
npm create vue
```

vite.config.ts

```sh
# 编译后，index.html 里面会有这个 base 路径
base: "/bbb/",
build: {
  outDir: "../../priv/static/bbb",
  emptyOutDir: true,
},
```

package.json

scripts 字段下

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

  @index_html_path :code.priv_dir(:web_demo) |> Path.join("static/bbb/index.html")

  def home(conn, _params) do
    case File.read(@index_html_path) do
      {:ok, html_content} ->
        conn
        |> put_root_layout(false)
        |> html(html_content)

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> text("前端静态文件未找到，请先执行 npm run build")
    end
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
