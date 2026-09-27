# hook

## 说明

hook 实际上是把 dom 的生命周期和 elixir 进行绑定。

场景如复杂，则 Hook 使用独立的 js

phx-hook 的值不得以点开头，id 必须写

## 例子

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home

  live "/live", PageLive
end
```

page_live.ex

```elixir
defmodule WebDemoWeb.PageLive do
  use WebDemoWeb, :live_view

  embed_templates "page_live.html"

  def mount(_params, _session, socket) do
    {:ok, assign(socket, msg: "aaa")}
  end

  def handle_event("js_to_elixir", %{"client_data" => value}, socket) do
    socket = push_event(socket, "server_msg", %{reply_msg: "服务端已收到: #{value}"})
    {:noreply, socket}
  end

  def handle_event("elixir_to_js", _params, socket) do
    socket = push_event(socket, "server_msg", %{reply_msg: "你点击了 elixir-to-js 按钮！"})
    {:noreply, socket}
  end
end
```

page_live.html.heex

```html
<div class="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
  <h3 class="text-xl font-bold">Demo Hook Page</h3>
  <div id="phx-hook-must-has-unique-id-xxx" phx-hook="DemoHook" class="flex flex-col items-center space-y-3">
    <div id="static" data-msg="{@msg}">{@msg}</div>
    <button id="js-to-elixir" class="btn btn-primary">js 通知 elixir</button>
    <button id="elixir-to-js" class="btn btn-secondary">elixir 发给 js</button>
    <div id="log-msg" class="text-sm opacity-80">信息显示</div>
  </div>
</div>
```

demo_hook.js

```javascript
class DemoHook {
  mounted() {
    const staticEl = this.el.querySelector("#static");
    const staticVal = staticEl ? staticEl.dataset.msg : "";
    console.log("从服务端静态获取的 msg:", staticVal);

    const logMsg = this.el.querySelector("#log-msg");

    const btnJsToElixir = this.el.querySelector("#js-to-elixir");
    if (btnJsToElixir) {
      btnJsToElixir.addEventListener("click", () => {
        const payload = { client_data: "来自前端 js_to_elixir 的点击" };
        this.pushEvent("js_to_elixir", payload, (reply) => {
          console.log(reply);
        });
      });
    }

    const btnElixirToJs = this.el.querySelector("#elixir-to-js");
    if (btnElixirToJs) {
      btnElixirToJs.addEventListener("click", () => {
        const payload = { click_info: "点击了 elixir_to_js" };
        this.pushEvent("elixir_to_js", payload, (reply) => {
          console.log(reply);
        });
      });
    }

    this.handleEvent("server_msg", (payload) => {
      if (logMsg) {
        logMsg.innerText = payload.reply_msg;
      }
    });
  }

  beforeUpdate() {
    console.log("DemoHook beforeUpdate", this.el);
  }

  updated() {
    console.log("DemoHook updated", this.el);
  }

  destroyed() {
    console.log("DemoHook destroyed", this.el);
  }

  disconnected() {
    console.log("DemoHook disconnected", this.el);
  }

  reconnected() {
    console.log("DemoHook reconnected", this.el);
  }
}

export default new DemoHook();
```

app.js

```javascript
import DemoHook from "./demo_hook"

......

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, DemoHook},
})
```
