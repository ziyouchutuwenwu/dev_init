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
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok,
     socket
     |> assign(
       number: 0,
       async_status: "无任务",
       param_value: "",
       form_hint: "等待输入..."
     )}
  end

  def handle_params(params, _uri, socket) do
    value = Map.get(params, "arg1", "默认值")
    {:noreply, assign(socket, :param_value, value)}
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

  def handle_event("heavy_calc", _params, socket) do
    socket =
      start_async(socket, :heavy_job, fn ->
        Process.sleep(2000)
        "计算完成！结果为：999"
      end)

    {:noreply, assign(socket, :async_status, "正在拼命计算中...")}
  end

  def handle_event("elixir_push_js", _params, socket) do
    socket = push_event(socket, "elixir_push_js", %{msg: "啊啊啊啊啊啊啊啊"})
    {:noreply, socket}
  end

  def handle_event("input_change", %{"username" => current_text}, socket) do
    hint_message =
      if String.length(current_text) < 3 do
        "❌ 用户名太短（当前长度：#{String.length(current_text)}）"
      else
        "✅ 长度合格！"
      end

    {:noreply, assign(socket, :form_hint, hint_message)}
  end

  def handle_async(:heavy_job, {:ok, result_string}, socket) do
    {:noreply, assign(socket, :async_status, result_string)}
  end

  def handle_async(:heavy_job, {:exit, _reason}, socket) do
    {:noreply, assign(socket, :async_status, "任务超时或崩溃！")}
  end

  defp increment(number), do: number + 1
  defp decrement(number), do: number - 1
end
```

page_live.html.heex

```html
<div>
  <h3>phx-click 触发服务端的 handle_event</h3>
  <div>{@number}</div>
  <!-- phx-click 触发服务端的 handle_event -->
  <button phx-click="inc">+</button>
  <button phx-click="dec">-</button>
</div>

<hr />

<div>
  <h3>js 主动 pushEvent 调用服务端</h3>
  <!-- phx-hook 必须以 . 开头, id 属性必须要写 -->
  <button phx-hook=".hook_aaa" id="btn1">clear</button>
</div>
<hr />

<div>
  <h3>js 修改 url，触发服务端 handle_params</h3>
  <div>数据: {@param_value}</div>
  <.link patch={~p"/live?arg1=aaa"}>修改 url</.link>
</div>

<hr />

<div>
  <h3>测试 handle_event 处理 start_async</h3>
  <div>异步任务状态：{@async_status}</div>
  <button phx-click="heavy_calc">耗时计算</button>
</div>

<hr />

<div>
  <h3>服务端用 push_event 来通知客户端</h3>
  <button phx-click="elixir_push_js">elixir 通知 js</button>
  <div phx-hook=".hook_bbb" id="elixir_push_js_container"></div>
</div>

<hr />

<div>
  <h3>表单实时触发 phx-change</h3>
  <form phx-change="input_change">
    <label>输入用户名：</label>
    <input type="text" name="username" placeholder="请输入..." />
  </form>
  <div>提示：{@form_hint}</div>
</div>

<hr />

<div>
  <h3>独立组建渲染（phx-target）</h3>
  <.live_component module={WebDemoWeb.Components.DemoComponent} id="demo1" />
</div>

<script :type={Phoenix.LiveView.ColocatedHook} name=".hook_aaa">
  // @ 代表 assets 目录
  // import AAA from "@/js/aaa"
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

<script :type={Phoenix.LiveView.ColocatedHook} name=".hook_bbb">
  export default {
    mounted() {
      this.handleEvent("elixir_push_js", (payload) => {
        alert(`js 收到服务端推送过来的消息: ${payload.msg}`);
      });
    }
  }
</script>
```

demo_component.ex

```elixir
defmodule WebDemoWeb.Components.DemoComponent do
  use WebDemoWeb, :live_component

  def update(_assigns, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("like", _params, socket) do
    {:noreply,
     update(socket, :count, fn count ->
       count + 1
     end)}
  end
end
```

demo_component.html.heex

```html
<div>
  <button phx-click="like" phx-target="{@myself}">点赞</button>
  <span>赞：{@count}</span>
</div>
```
