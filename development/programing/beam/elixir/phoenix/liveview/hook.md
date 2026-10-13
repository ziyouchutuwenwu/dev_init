# hook

## 说明

有些东西没办法在 liveview 处理，必须要在 js 处理

## 例子

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  live "/", DemoLive
end
```

demo_live.ex

```elixir
defmodule WebDemoWeb.DemoLive do
  use WebDemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, show: true)}
  end

  def handle_event("inc", _params, socket) do
    new_count = socket.assigns.count + 1
    {:noreply, assign(socket, count: new_count)}
  end

  def handle_event("zero", _params, socket) do
    {:noreply, assign(socket, count: 0)}
  end

  def handle_event("toggle", _params, socket) do
    new_show = !socket.assigns.show
    {:noreply, assign(socket, show: new_show)}
  end
end
```

demo_live.html.heex

```html
<div>
  <h2>演示</h2>

  <div>
    <button phx-click="inc">inc</button>
    <button phx-click="zero">zero</button>
    <button phx-click="toggle">toggle</button>
  </div>

  <%= if @show do %>
    <div id="aaa" phx-hook="DemoHook">
      aaa，计数: {@count}
    </div>
  <% end %>

  <div>
    bbb <span id="bbb"></span>
  </div>
</div>
```

demo_hook.js

```javascript
function log(msg) {
  const bbb = document.getElementById("bbb");
  if (bbb) bbb.innerText = msg;
}

export const DemoHook = {
  mounted() {
    log("on mounted");
    this.el.style.border = "2px solid blue";

    this.seconds = 0;
    this.timer = setInterval(() => {
      this.seconds++;
    }, 1000);

    this.el.onclick = () => {
      alert("元素已连续存活: " + this.seconds + " 秒");
    };
  },

  beforeUpdate() {
    log("on beforeUpdate");
    this.el.style.opacity = "0.4";
  },

  updated() {
    log("on updated");
    this.el.style.opacity = "1";
    this.el.style.color = "green";
    setTimeout(() => {
      if (this.el) this.el.style.color = "black";
    }, 300);
  },

  destroyed() {
    log("on destroyed");
    clearInterval(this.timer);
  },

  disconnected() {
    log("on disconnected");
    this.el.style.opacity = "0.2";
  },

  reconnected() {
    log("on reconnected");
    this.el.style.opacity = "1";
  }
};
```

app.js

```javascript
import DemoHook from "./demo_hook"

......

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  // 这里注册
  hooks: {DemoHook},
})
```
