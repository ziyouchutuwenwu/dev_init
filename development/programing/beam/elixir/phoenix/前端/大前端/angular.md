# angular

## 说明

html 是 js 动态渲染出来的

## 步骤

位置规划

```sh
angular 源码
  assets/angular

打包以后
  priv/static/angular
```

angular.json

```json
"outputPath": {
  "base": "../../priv/static/angular",
  "browser": ""
}
```

lib/web_demo_web.ex

添加 angular 目录

```elixir
def static_paths, do: ~w(assets angular fonts images favicon.ico robots.txt)
```

页面 layout

lib/web_demo_web/components/layouts/angular.html.heex

参考 `priv/static/angular/index.html`

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    <title>WebDemo</title>
    <base href="/" />
    <link rel="stylesheet" href="/angular/styles.css" />
    <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
  </head>
  <body>
    <app-root></app-root>
    <script src="/angular/main.js" type="module"></script>
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
    ng_dir = Path.join(File.cwd!(), "assets/angular")
    if File.dir?(ng_dir) do
      System.cmd("npm", ~w(run watch), cd: ng_dir, into: IO.stream(:stdio, :line))
    else
      Mix.raise("Angular project not found at #{ng_dir}")
    end
  end
end
```

config/dev.exs

```elixir
watchers: [
  esbuild: {Esbuild, :install_and_run, [:web_demo, ~w(--sourcemap=inline --watch)]},
  tailwind: {Tailwind, :install_and_run, [:web_demo, ~w(--watch)]},
  angular: {Ng.Watcher, :run, []}
]
```

lib/ng/mix_task/ng_build.ex

```elixir
# ng.build 在这里注册
defmodule Mix.Task.NgBuild do
  use Mix.Task

  def run(args) do
    ng_dir = Path.join(File.cwd!(), "assets/angular")
    build_args = ["run", "build"] ++ args

    case System.cmd("npm", build_args, cd: ng_dir, into: IO.stream(:stdio, :line)) do
      {_, 0} -> Mix.shell().info("✓ Angular build completed")
      _ -> Mix.raise("Angular build failed")
    end
  end
end
```

mix.exs

```elixir
defp aliases do
  [
    # "assets.build": ["compile", "tailwind web_demo", "esbuild web_demo"],
    "assets.build": ["compile", "ngbuild", "tailwind web_demo", "esbuild web_demo"],
    # ...
  ]
end
```

验证

```sh
mix phx.server
```
