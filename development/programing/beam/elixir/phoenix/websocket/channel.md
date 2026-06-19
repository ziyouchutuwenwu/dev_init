# channel

## 说明

封装过的 websocket

## 例子

路由

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/chat", ChatLive, :index
  end
end
```

endpoint.ex

```elixir
socket "/socket", WebDemoWeb.UserSocket,
  websocket: [connect_info: [session: @session_options]],
  longpoll: [connect_info: [session: @session_options]]
```

user_socket.ex

```elixir
defmodule WebDemoWeb.UserSocket do
  use Phoenix.Socket

  # channel 在这里注册
  # 支持通配符
  channel "room:*", WebDemoWeb.RoomChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # 如果两个 websocket 同时返回一样的 id, 则旧的连接会被断开
  @impl true
  def id(_socket), do: nil
end
```

room_channel.ex

```elixir
defmodule WebDemoWeb.RoomChannel do
  use WebDemoWeb, :channel
  require Logger

  @impl true
  def join("room:abc", _message, socket) do
    Logger.debug("on join room:abc")
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def handle_in("room_msg", %{"body" => body}, socket) do
    Logger.debug("on room_msg")
    broadcast!(socket, "room_msg", %{body: body})
    {:noreply, socket}
  end

  # 只拦截 handle_out
  # intercept ["room_msg"]

  # @impl true
  # def handle_out("room_msg", payload, socket) do
  #   Logger.debug("拦截返回客户端的消息 #{inspect(payload)}")
  #   push(socket, "room_msg", payload)
  #   {:noreply, socket}
  # end
end
```

chat_live.ex

```elixir
defmodule WebDemoWeb.ChatLive do
  use WebDemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :user, random_user())}
  end

  defp random_user, do: "User#{:rand.uniform(999)}"
end
```

chat_live.html.heex

```html
<Layouts.app flash="{@flash}">
  <%!-- Header --%>
  <div class="flex items-center justify-between px-4 pb-2 pt-2">
    <div>
      <h1 class="text-lg font-bold">聊天演示</h1>
      <p class="text-xs text-base-content/60">频道消息演示 — {@user}</p>
    </div>
  </div>

  <div class="flex h-full min-h-[calc(100vh-100px)] gap-3 px-4 pb-4">
    <%!-- Left: room controls (15%) --%>
    <div class="flex w-[15%] flex-col rounded-xl border border-base-300/60 bg-base-100 p-3 shadow-sm">
      <div class="mb-2 flex items-center justify-between">
        <p class="text-sm font-semibold text-base-content/70">房间 abc</p>
        <button id="clear-room" class="text-xs text-base-content/40 hover:text-red-500">清除</button>
      </div>
      <div class="flex flex-col gap-2">
        <button
          id="enter-room"
          class="w-full rounded-lg bg-blue-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-blue-600">
          进入
        </button>
        <button
          id="leave-room"
          class="w-full rounded-lg bg-red-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-red-600">
          离开
        </button>
      </div>
      <div id="room-msg" class="mt-2 flex-1 overflow-auto text-xs text-base-content/60"></div>
    </div>

    <%!-- Center: chat messages (50%) --%>
    <div class="flex w-[35%] flex-col rounded-xl border border-base-300/60 bg-base-100 shadow-sm">
      <div class="flex items-center justify-between border-b border-base-200/60 px-3 py-2">
        <h2 class="text-sm font-semibold">消息</h2>
        <button id="clear-msg" class="text-xs text-base-content/40 hover:text-red-500">清除</button>
      </div>
      <div id="msg" class="flex-1 overflow-auto p-3 text-sm"></div>
      <div class="mt-auto border-t border-base-200/60 px-3 py-2">
        <input
          id="chat-input"
          type="text"
          placeholder="输入消息..."
          class="w-full rounded-lg border border-base-300/60 px-3 py-1.5 text-sm outline-none transition-shadow focus:shadow-[0_0_0_2px] focus:shadow-blue-500/20" />
      </div>
    </div>

    <%!-- Right: telemetry (35%) --%>
    <div class="flex w-[50%] flex-col rounded-xl border border-base-300/60 bg-base-100 p-3 shadow-sm">
      <div class="mb-2 flex items-center justify-between">
        <p class="text-sm font-semibold text-base-content/70">数据</p>
        <button id="clear-telemetry" class="text-xs text-base-content/40 hover:text-red-500">清除</button>
      </div>
      <div id="telemetry" class="flex-1 overflow-auto font-mono text-[11px] leading-relaxed"></div>
    </div>
  </div>
</Layouts.app>
```

user_socket.js

```javascript
import { Socket } from "phoenix";

const socket = new Socket("/socket", { params: {} });
socket.connect();

let channel = null;

const enterRoom = document.getElementById("enter-room");
const leaveRoom = document.getElementById("leave-room");
const roomMsg = document.getElementById("room-msg");
const inputContent = document.getElementById("chat-input");
const htmlMsg = document.getElementById("msg");
const telemetry = document.getElementById("telemetry");

document.getElementById("clear-room")?.addEventListener("click", () => (roomMsg.innerHTML = ""));
document.getElementById("clear-msg")?.addEventListener("click", () => (htmlMsg.innerHTML = ""));
document.getElementById("clear-telemetry")?.addEventListener("click", () => (telemetry.innerHTML = ""));
function addTelemetry(dir, data) {
  if (!telemetry) return;
  const item = document.createElement("div");
  item.className = "border-b border-base-200/30 pb-1 text-xs";
  const label = dir === "发" ? "发" : "收";
  item.innerHTML = `<span class="font-semibold ${dir === "发" ? "text-blue-500" : "text-green-500"}">${label}</span> ${JSON.stringify(data)}`;
  telemetry.appendChild(item);
  telemetry.scrollTop = telemetry.scrollHeight;
}

enterRoom.addEventListener("click", () => {
  if (channel) channel.leave();
  channel = socket.channel("room:abc", {});
  channel.on("room_msg", (payload) => {
    addTelemetry("收", [channel.joinRef(), null, channel.topic, "room_msg", payload]);
    const msgItem = document.createElement("p");
    msgItem.innerText = `on room_msg ${payload.body}`;
    htmlMsg.appendChild(msgItem);
    htmlMsg.scrollTop = htmlMsg.scrollHeight;
  });
  addTelemetry("发", [null, "phx_join", "room:abc", "phx_join", {}]);
  channel
    .join()
    .receive("ok", (resp) => {
      addTelemetry("收", [channel.joinRef(), null, channel.topic, "phx_join_reply", resp]);
      const item = document.createElement("p");
      item.innerText = "成功加入房间";
      roomMsg.appendChild(item);
    })
    .receive("error", (resp) => {
      addTelemetry("收", [channel.joinRef(), null, channel.topic, "phx_join_reply", resp]);
      const item = document.createElement("p");
      item.innerText = "加入房间失败: " + resp.reason;
      item.className = "text-red-500";
      roomMsg.appendChild(item);
    });
});

leaveRoom.addEventListener("click", () => {
  if (channel) {
    const ch = channel;
    addTelemetry("发", [ch.joinRef(), "phx_leave", ch.topic, "phx_leave", {}]);
    ch.leave().receive("ok", () => {
      addTelemetry("收", [ch.joinRef(), null, ch.topic, "phx_leave_reply", {}]);
    });
    channel = null;
  } else {
    addTelemetry("发", [null, "phx_leave", "room:abc", "phx_leave", {}]);
    addTelemetry("收", [null, null, "room:abc", "phx_leave_reply", {}]);
  }
  const item = document.createElement("p");
  item.innerText = "离开房间";
  roomMsg.appendChild(item);
});

inputContent.addEventListener("keypress", (event) => {
  if (event.key === "Enter") {
    const body = inputContent.value.trim();
    if (!body) return;
    const payload = { body };
    const push = channel.push("room_msg", payload);
    addTelemetry("发", [channel.joinRef(), push.ref, channel.topic, "room_msg", payload]);
    inputContent.value = "";
  }
});

document.getElementById("clear-room")?.addEventListener("click", () => (roomMsg.innerHTML = ""));
document.getElementById("clear-msg")?.addEventListener("click", () => (htmlMsg.innerHTML = ""));
document.getElementById("clear-telemetry")?.addEventListener("click", () => (telemetry.innerHTML = ""));
```
