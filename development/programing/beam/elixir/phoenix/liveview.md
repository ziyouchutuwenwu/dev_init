# liveview

## 步骤

### 创建项目

```sh
mix phx.new web_demo --no-ecto --no-gettext
```

### 配置路由

```elixir
live "/live", PageLive
```

### 代码

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

page_live.ex

```elixir
defmodule WebDemoWeb.PageLive do
  use WebDemoWeb, :live_view
  alias WebDemoWeb.Views.Shared.Live

  def render(assigns) do
    ~H"""
    <Live.demo number={@number} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(number: 0)}
  end

  def handle_event("inc", _params, socket) do
    {:noreply, socket |> update(:number, &(&1 + 1))}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, socket |> update(:number, &(&1 - 1))}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, socket |> assign(number: 0)}
  end
end
```
