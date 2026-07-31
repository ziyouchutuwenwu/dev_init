# angular

## 说明

js 动态渲染

## 步骤

位置

```sh
# angular 源码位置
assets/aaa
```

结构如下

```sh
assets/aaa
├── angular.json
├── node_modules
├── package.json
├── package-lock.json
├── public
├── README.md
├── src
├── tsconfig.app.json
├── tsconfig.json
└── tsconfig.spec.json
```

```sh
# 打包后位置
priv/static/bbb
```

angular.json，查看 defaultConfiguration，记住

```sh
projects -> xxx -> architect -> build -> options
```

```sh
# 实际上就是替换 browser 字段
"outputPath": {
  "base": "../../priv/static/bbb",
  "browser": ""
}
```

package.json

```json
"scripts": {
  "build": "ng build --base-href /bbb/",
  "watch": "ng build --watch --configuration development --base-href /bbb/",
}
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

# angular
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
        |> text("前端静态文件未找到，请稍后刷新页面")
    end
  end
end
```

config/dev.exs

```elixir
watchers: [
  esbuild: ......,
  tailwind: ......,

  angular: {Mix.Tasks.Cmd, :run, [["npm", "run", "watch", "--prefix", "assets/aaa"]]}
]
```

mix.exs

```elixir
defp aliases do
  [
    "assets.deploy": [
      "cmd -- npm run build --prefix assets/aaa",
      ......
      ],
  ]
end
```

验证

```sh
mix phx.server
```
