# layout

## 说明

```sh
# components/layouts.ex
theme_toggle  切换主题
app           顶部导航栏，内部带切换主题
flash_group   弹出信息
```

## 用法

### 自带

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/flash-demo", PageController, :flash_demo
  get "/app-demo", PageController, :app_demo
end
```

page_controller.ex

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :put_layout, html: {WebDemoWeb.Layouts, :app}

  def home(conn, _params) do
    render(conn, :home)
  end

  def flash_demo(conn, _params) do
    conn
    |> put_flash(:info, "aaaaaaa")
    |> render(:flash_demo)
  end

  def app_demo(conn, _params) do
    conn
    |> render(:app_demo)
  end
end
```

flash_demo.html.heex

```html
<div class="text-center">
  <h1 class="text-2xl font-semibold">Flash Demo</h1>
  <p class="mt-4 text-base-content/70">查看右上角的 flash 提示（由 app layout 自动渲染）。</p>
</div>
```

app_demo.html.heex

```html
<h1 class="text-2xl font-semibold">App Layout Demo</h1>
<p class="mt-4 text-base-content/70">
  这个页面用了
  <code phx-no-curly-interpolation class="bg-base-200 px-1.5 py-0.5 rounded">{WebDemoWeb.Layouts, :app}</code>
  layout。
</p>
<p class="mt-2 text-base-content/70">flash 由 app layout 自动渲染（看右上角），顶部导航栏也来自 app layout。</p>
```

### 自定义

自定义 layout

```sh
components/layouts/xxx.html.heex
```

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: {WebDemoWeb.Layouts, :xxx})
  end
end
```

或者

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :put_layout, html: {WebDemoWeb.Layouts, :xxx}

  def home(conn, _params) do
    render(conn, :home)
  end
end
```
