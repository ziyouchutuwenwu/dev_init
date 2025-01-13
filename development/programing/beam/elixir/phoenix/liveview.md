# liveview

## 步骤

### 创建项目

```sh
mix phx.new web_demo --no-ecto --no-gettext
```

### 配置路由

```elixir
live "/live-demo", PageLive
```

### 创建 live 代码

lib/web_demo_web/my_live/page_live.ex

```elixir

defmodule WebDemoWeb.PageLive do
  use WebDemoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>{@number}</div>

    <button phx-click="inc">+</button>

    <button phx-click="dec">-</button>

    <button phx-click="clear">clear</button>
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

### 单元测试

test/web_demo_web/live/live_test.exs

```elixir
defmodule WebDemoWeb.PageLiveTest do
  use WebDemoWeb.ConnCase
  import Phoenix.LiveViewTest

  test "disconnect and connected render", %{conn: conn} do
    {:ok, page_live, html} = live(conn, "/live-demo")
    assert html =~ "0"
    assert render(page_live) =~ "0"
  end

  test "inc and dec", %{conn: conn} do
    {:ok, page_live, _html} = live(conn, "/live-demo")
    assert render_click(page_live, :inc, %{}) =~ "1"
    assert render_click(page_live, :inc, %{}) =~ "2"
    assert render_click(page_live, :inc, %{}) =~ "3"
    assert render_click(page_live, :dec, %{}) =~ "2"
    assert render_click(page_live, :dec, %{}) =~ "1"
    assert render_click(page_live, :dec, %{}) =~ "0"
  end
end
```
