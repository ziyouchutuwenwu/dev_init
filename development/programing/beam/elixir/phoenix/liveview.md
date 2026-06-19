# liveview

## 说明

用的是 websocket，不需要刷新页面

## 例子

路由

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home

  live "/live", PageLive
end
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
<div>{@number}</div>
<button phx-click="inc">+</button>
<button phx-click="dec">-</button>
<button phx-click="clear">clear</button>
<div>结束</div>
```
