# liveview

## 说明

ex 自动在当前目录下加载 heex

## 步骤

### 准备

```sh
mix phx.new web_demo --no-ecto --no-gettext
```

### 路由

```elixir
# 和普通路由没有区别
live "/live", PageLive
```

### 代码

page_live.ex

```elixir
defmodule WebDemoWeb.PageLive do
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

page_live.html.heex

```html
<div>开始</div>
<WebDemoWeb.Views.Shared.Live.demo number="{@number}" />
<div>结束</div>
```

live_component.ex

```elixir
defmodule WebDemoWeb.Views.Shared.Live do
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
