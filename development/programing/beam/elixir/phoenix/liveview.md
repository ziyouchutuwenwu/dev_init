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
    {:noreply, socket |> update(:number, fn value -> increment(value) end)}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, socket |> update(:number, fn value -> decrement(value) end)}
  end

  def handle_event("clear", _params, socket) do
    number_before_clear = socket.assigns.number
    {:reply, %{number_before_clear: number_before_clear}, assign(socket, :number, 0)}
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

<!-- phx-hook 必须以 . 开头 -->
<!-- 这个 dom 挂载以后触发 -->
<button phx-hook=".clear_notify" id="clear-btn">clear</button>
<script :type={Phoenix.LiveView.ColocatedHook} name=".clear_notify">
  // import xxxx
  export default {
    // liveview 组件的生命周期
    mounted() {

      this.el.addEventListener("click", () => {
        this.pushEvent("clear", {}, (reply) => {
          alert(`已清除！清除前的值是：${reply.number_before_clear}`);
        });
      });
    }
  }
</script>
<div>结束</div>
```
