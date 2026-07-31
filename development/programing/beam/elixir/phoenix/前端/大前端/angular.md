# angular

## 说明

html 是 js 动态渲染出来的

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

angular.json

```sh
projects -> xxx -> architect -> build -> options
```

```json
"outputPath": {
  "base": "../../priv/static/bbb",
  "browser": ""
}
```

lib/web_demo_web.ex

```elixir
def static_paths, do: ~w(
  bbb
  ......
)
```

页面 layout

lib/web_demo_web/components/layouts/angular.html.heex

参考 angular 编译后的 index.html

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta name="csrf-token" content="{get_csrf_token()}" />

    <meta charset="utf-8" />
    <title>WebDemo</title>
    <base href="/" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" type="image/x-icon" href="favicon.ico" />
    <link rel="stylesheet" href="/bbb/styles.css" />
  </head>
  <body>
    <app-root></app-root>
    <script src="/bbb/main.js" type="module"></script>
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

# 前端都给 angular
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
    render(conn, :home, layout: {WebDemoWeb.Layouts, :angular})
  end
end
```

或者

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :put_layout, html: {WebDemoWeb.Layouts, :angular}

  def home(conn, _params) do
    render(conn, :home)
  end
end
```

构建

lib/ng/watcher.ex

```elixir
defmodule Ng.Watcher do
  def run do
    ng_dir = Path.join(File.cwd!(), "assets/aaa")
    if File.dir?(ng_dir) do
      System.cmd("npm", ~w(run watch), cd: ng_dir, into: IO.stream(:stdio, :line))
    else
      Mix.raise("angular project not found at #{ng_dir}")
    end
  end
end
```

config/dev.exs

```elixir
watchers: [
  esbuild: ......,
  tailwind: ......,
  angular: {Ng.Watcher, :run, []}
]
```

lib/ng/mix/ng_build.ex

```elixir
# ng.build 在这里注册
defmodule Mix.Task.Ng.Build do
  use Mix.Task

  def run(args) do
    ng_dir = Path.join(File.cwd!(), "assets/aaa")
    build_args = ["run", "build"] ++ args

    case System.cmd("npm", build_args, cd: ng_dir, into: IO.stream(:stdio, :line)) do
      {_, 0} -> Mix.shell().info("angular build completed")
      _ -> Mix.raise("angular build failed")
    end
  end
end
```

mix.exs

```elixir
defp aliases do
  [
    "assets.build": [
      "ng.build"
      # ......
    ],
    # ......
  ]
end
```

验证

```sh
mix phx.server
```
