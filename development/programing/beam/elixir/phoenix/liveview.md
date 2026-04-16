# liveview

## 场景

用的是 websocket，不需要刷新页面

## 说明

注意默认渲染的名字

```sh
xxx_live.ex
xxx.html.heex
```

## 步骤

### 准备

```sh
mix phx.new web_demo --no-ecto --no-gettext
```

### 路由

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home

  # 和普通路由没有区别
  live "/live", Live.Page
end
```

### 代码

lib/web_demo_web/live/page/page_live.ex

```elixir
defmodule WebDemoWeb.Live.Page do
  use WebDemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(number: 0)}
  end

  def handle_event("inc", _params, socket) do
    {:noreply, update(socket, :number, &increment/1)}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, update(socket, :number, &decrement/1)}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, socket |> assign(number: 0)}
  end

  defp increment(number) do
    number + 1
  end

  defp decrement(number) do
    number - 1
  end
end
```

lib/web_demo_web/live/page/page.html.heex

```html
<div>开始</div>
<WebDemoWeb.Live.Page.Components.AAA.demo number="{@number}" />
<div>结束</div>
```

lib/web_demo_web/live/page/components/aaa.ex

```elixir
defmodule WebDemoWeb.Live.Page.Components.AAA do
  use Phoenix.Component

  def demo(assigns) do
    ~H"""
    <div>{@number}</div>

    <button phx-click="inc">+</button>

    <button phx-click="dec">-</button>

    <button phx-click="clear">clear</button>
    """
  end
end
```
