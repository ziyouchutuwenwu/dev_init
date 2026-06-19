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
  websocket: [connect_info: [:x_headers, :uri, :peer_data, session: @session_options]],
  longpoll: [connect_info: [:x_headers, :uri, :peer_data, session: @session_options]]
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
    Phoenix.Channel.broadcast!(socket, "room_msg", %{body: body})
    {:noreply, socket}
  end

  # 只拦截 handle_out
  # intercept ["room_msg"]

  # @impl true
  # def handle_out("room_msg", payload, socket) do
  #   Logger.debug("拦截返回客户端的消息 #{inspect(payload)}")
  #   Phoenix.Channel.push(socket, "room_msg", payload)
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

  <div class="flex h-full min-h-[calc(100vh-100px)] gap-3 px-4 pb-4" id="chat-app" phx-hook="chat_room">
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
      <div class="mb-2">
        <div class="flex items-center justify-between">
          <p class="text-sm font-semibold text-base-content/70">数据</p>
          <button id="clear-data" class="text-xs text-base-content/40 hover:text-red-500">清除</button>
        </div>
        <p class="mt-1 text-[10px] text-base-content/40">格式: [room_ref, msg_id, topic, event, payload]</p>
      </div>
      <div id="data" class="flex-1 overflow-auto font-mono text-[11px] leading-relaxed"></div>
    </div>
  </div>
</Layouts.app>
```

chat/chat_room.js

```javascript
import { Socket } from "phoenix";
import { ViewHook } from "phoenix_live_view";

class ChatRoom extends ViewHook {
  // ViewHook 里面的
  mounted() {
    this.socket = new Socket("/socket", { params: {} });
    this.channel = null;
    this.socket.connect();

    this.enterRoom = document.getElementById("enter-room");
    this.leaveRoom = document.getElementById("leave-room");
    this.roomMsg = document.getElementById("room-msg");
    this.inputContent = document.getElementById("chat-input");
    this.htmlMsg = document.getElementById("msg");
    this.data = document.getElementById("data");

    document.getElementById("clear-room")?.addEventListener("click", this.handleClearRoom.bind(this));
    document.getElementById("clear-msg")?.addEventListener("click", this.handleClearMsg.bind(this));
    document.getElementById("clear-data")?.addEventListener("click", this.handleClearData.bind(this));
    this.enterRoom.addEventListener("click", this.handleEnterRoom.bind(this));
    this.leaveRoom.addEventListener("click", this.handleLeaveRoom.bind(this));
    this.inputContent.addEventListener("keypress", this.handleInputKeypress.bind(this));
  }

  // ViewHook 里面的
  destroyed() {
    if (this.channel) {
      this.channel.leave();
      this.channel = null;
    }
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }

  handleClearRoom() {
    this.roomMsg.innerHTML = "";
  }

  handleClearMsg() {
    this.htmlMsg.innerHTML = "";
  }

  handleClearData() {
    this.data.innerHTML = "";
  }

  handleEnterRoom() {
    this.createChannel();
    this.channel.on("room_msg", this.handleRoomMsg.bind(this));
    this.addData("发", [null, "phx_join", "room:abc", "phx_join", {}]);
    this.channel.join().receive("ok", this.handleJoinOk.bind(this)).receive("error", this.handleJoinError.bind(this));
  }

  handleRoomMsg(payload) {
    this.addData("收", [this.channel.joinRef(), null, this.channel.topic, "room_msg", payload]);
    var msgItem = document.createElement("p");
    msgItem.innerText = "收到: " + payload.body;
    this.htmlMsg.appendChild(msgItem);
    this.htmlMsg.scrollTop = this.htmlMsg.scrollHeight;
  }

  handleJoinOk(resp) {
    this.addData("收", [this.channel.joinRef(), null, this.channel.topic, "phx_join_reply", resp]);
    var item = document.createElement("p");
    item.innerText = "成功加入房间";
    this.roomMsg.appendChild(item);
  }

  handleJoinError(resp) {
    this.addData("收", [this.channel.joinRef(), null, this.channel.topic, "phx_join_reply", resp]);
    var item = document.createElement("p");
    item.innerText = "加入房间失败: " + resp.reason;
    item.className = "text-red-500";
    this.roomMsg.appendChild(item);
  }

  handleLeaveRoom() {
    if (this.channel) {
      this.addData("发", [this.channel.joinRef(), "phx_leave", this.channel.topic, "phx_leave", {}]);
      var ch = this.channel;
      var self = this;
      this.channel = null;
      ch.leave().receive("ok", function () {
        self.addData("收", [ch.joinRef(), null, ch.topic, "phx_leave_reply", {}]);
      });
    } else {
      this.addData("发", [null, "phx_leave", "room:abc", "phx_leave", {}]);
      this.addData("收", [null, null, "room:abc", "phx_leave_reply", {}]);
    }
    var item = document.createElement("p");
    item.innerText = "离开房间";
    this.roomMsg.appendChild(item);
  }

  handleInputKeypress(event) {
    if (event.key !== "Enter") return;
    if (!this.channel) return;
    var body = this.inputContent.value.trim();
    if (!body) return;
    var payload = { body: body };
    var push = this.channel.push("room_msg", payload);
    push.receive("ok", this.handleSendOk.bind(this));
    this.addData("发", [this.channel.joinRef(), push.ref, this.channel.topic, "room_msg", payload]);
    this.inputContent.value = "";
  }

  handleSendOk(resp) {
    var msgItem = document.createElement("p");
    msgItem.className = "text-blue-600 font-medium";
    msgItem.innerText = "我: " + resp.body;
    this.htmlMsg.appendChild(msgItem);
    this.htmlMsg.scrollTop = this.htmlMsg.scrollHeight;
  }

  addData(dir, payload) {
    if (!this.data) return;
    var item = document.createElement("div");
    item.className = "border-b border-base-200/30 pb-1 text-xs";
    var label = dir === "发" ? "发" : "收";
    item.innerHTML =
      '<span class="font-semibold ' +
      (dir === "发" ? "text-blue-500" : "text-green-500") +
      '">' +
      label +
      "</span> " +
      JSON.stringify(payload);
    this.data.appendChild(item);
    this.data.scrollTop = this.data.scrollHeight;
  }

  createChannel() {
    if (this.channel) this.channel.leave();
    this.channel = this.socket.channel("room:abc", {});
    return this.channel;
  }
}

export default ChatRoom;
```

chat/connector.js

```javascript
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import ChatRoom from "./chat_room";

class Connector {
  constructor() {
    this.liveSocket = null;
  }

  init() {
    var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    this.liveSocket = new LiveSocket("/live", Socket, {
      longPollFallbackMs: 2500,
      params: {
        _csrf_token: csrfToken,
      },
      hooks: {
        chat_room: ChatRoom,
      },
    });
  }

  connect() {
    this.liveSocket.connect();
  }

  disconnect() {
    if (!this.liveSocket) return;
    this.liveSocket.disconnect();
    this.liveSocket = null;
  }
}

export default Connector;
```

app.js

```javascript
import "phoenix_html";
import Connector from "./chat/connector";

var connector = new Connector();
connector.init();
connector.connect();
```
