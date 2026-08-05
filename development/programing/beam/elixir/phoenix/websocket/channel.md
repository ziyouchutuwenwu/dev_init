# channel

## 说明

一般用于多客户端之间通信

channel 是注册了某个 topic 的 handler

user_socket 在 websocket 的基础上，绑定了 user

user_socket 可以订阅多种 topic, 也就是支持多种 channel

## 例子

路由

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home
  live "/chat", ChatLive, :index
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

  # 支持多种 channel
  channel "room:*", WebDemoWeb.RoomChannel
  # channel "game:*", WebDemoWeb.GameChannel

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

  # js 里面， this.channel.join(); 时触发这里
  def join("room:abc", _message, socket) do
    Logger.debug("on join room:abc")
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

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

  defp random_user do
    "user#{:rand.uniform(999)}"
  end
end
```

chat_live.html.heex

```html
<Layouts.app flash="{@flash}">
  <div id="chat-root" phx-hook=".chat_room">
    <%!-- Header --%>
    <div class="flex items-center justify-between px-4 pb-2 pt-2">
      <div class="flex items-center gap-4">
        <h1 class="text-lg font-bold">聊天演示</h1>
        <div class="flex gap-2">
          <button
            id="enter-room"
            class="rounded-lg bg-blue-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-blue-600">
            进入
          </button>
          <button
            id="leave-room"
            class="rounded-lg bg-red-500 px-3 py-1.5 text-sm text-white transition-colors hover:bg-red-600">
            离开
          </button>
        </div>
      </div>
      <p class="text-xs text-base-content/60">频道消息演示 — {@user}</p>
    </div>

    <div class="flex h-full min-h-[calc(100vh-100px)] gap-3 px-4 pb-4">
      <%!-- Center: chat messages --%>
      <div class="flex w-[50%] flex-col rounded-xl border border-base-300/60 bg-base-100 shadow-sm">
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
  </div>
</Layouts.app>

<script :type="{Phoenix.LiveView.ColocatedHook}" name=".chat_room">
  import UserSocket from "@/js/chat/user_socket";
  import ChatRoom from "@/js/chat/chat_room";

  export default {
    mounted() {
      this.chatRoom = new ChatRoom();
      this.userSocket = new UserSocket();
      this.userSocket
        .connect()
        .then((socket) => this.chatRoom.addUser(socket))
        .catch((err) => console.error("chat 连接失败", err));
    },
    destroyed() {
      if (this.chatRoom) {
        this.chatRoom.destroyed();
        this.chatRoom = null;
      }
      if (this.userSocket) {
        this.userSocket.disconnect();
        this.userSocket = null;
      }
    },
  };
</script>
```

chat/chat_room.js

```javascript
class ChatRoom {
  constructor() {
    this.socket = null;
    this.channel = null;

    this.enterBtn = document.getElementById("enter-room");
    this.leaveBtn = document.getElementById("leave-room");
    this.htmlMsg = document.getElementById("msg");
    this.inputContent = document.getElementById("chat-input");
    this.data = document.getElementById("data");

    document.getElementById("clear-msg")?.addEventListener("click", this.handleClearMsg.bind(this));
    document.getElementById("clear-data")?.addEventListener("click", this.handleClearData.bind(this));
    this.enterBtn.addEventListener("click", this.handleEnterRoomClick.bind(this));
    this.leaveBtn.addEventListener("click", this.handleLeaveRoom.bind(this));
    this.inputContent.addEventListener("keypress", this.handleInputKeypress.bind(this));
  }

  addUser(socket) {
    this.socket = socket;
  }

  get topic() {
    return "room:abc";
  }

  enter() {
    return new Promise((resolve, reject) => {
      if (!this.socket) {
        reject(new Error("socket 未连接"));
        return;
      }
      if (this.channel) {
        resolve(this.channel);
        return;
      }
      this.channel = this.socket.channel(this.topic, {});
      this.channel.on("room_msg", (payload) => this.handleRoomMsg(payload));
      this.appendMsg("发", [this.channel.joinRef(), null, this.channel.topic, "phx_join", {}]);
      this.channel
        .join()
        .receive("ok", (resp) => {
          this.appendMsg("收", [this.channel.joinRef(), null, this.channel.topic, "phx_join_reply", resp]);
          this.appendSystemMsg("成功加入房间");
          resolve(this.channel);
        })
        .receive("error", (resp) => {
          this.appendMsg("收", [this.channel.joinRef(), null, this.channel.topic, "phx_join_reply", resp]);
          this.appendSystemMsg("加入房间失败: " + resp.reason, "text-red-500");
          this.channel = null;
          reject(resp);
        });
    });
  }

  leave() {
    return new Promise((resolve) => {
      if (!this.channel) {
        this.appendMsg("发", [null, "phx_leave", this.topic, "phx_leave", {}]);
        this.appendMsg("收", [null, null, this.topic, "phx_leave_reply", {}]);
        this.appendSystemMsg("离开房间");
        resolve();
        return;
      }
      this.appendMsg("发", [this.channel.joinRef(), "phx_leave", this.channel.topic, "phx_leave", {}]);
      var ch = this.channel;
      var self = this;
      this.channel = null;
      ch.leave().receive("ok", function () {
        self.appendMsg("收", [ch.joinRef(), null, ch.topic, "phx_leave_reply", {}]);
        self.appendSystemMsg("离开房间");
        resolve();
      });
    });
  }

  sendMsg(body) {
    return new Promise((resolve, reject) => {
      if (!this.channel) {
        reject(new Error("未加入房间"));
        return;
      }
      var payload = { body: body };
      var push = this.channel.push("room_msg", payload);
      push.receive("ok", (resp) => {
        this.handleSendOk(resp);
        resolve(resp);
      });
      push.receive("error", (resp) => reject(resp));
      this.appendMsg("发", [this.channel.joinRef(), push.ref, this.channel.topic, "room_msg", payload]);
    });
  }

  destroyed() {
    if (this.channel) {
      this.channel.leave();
      this.channel = null;
    }
  }

  handleClearMsg() {
    this.htmlMsg.innerHTML = "";
  }

  handleClearData() {
    this.data.innerHTML = "";
  }

  handleEnterRoomClick() {
    this.enter().catch(() => {});
  }

  handleRoomMsg(payload) {
    this.appendMsg("收", [this.channel.joinRef(), null, this.channel.topic, "room_msg", payload]);
    var msgItem = document.createElement("p");
    msgItem.innerText = "收到: " + payload.body;
    this.htmlMsg.appendChild(msgItem);
    this.htmlMsg.scrollTop = this.htmlMsg.scrollHeight;
  }

  handleLeaveRoom() {
    this.leave();
  }

  handleInputKeypress(event) {
    if (event.key !== "Enter") return;
    var body = this.inputContent.value.trim();
    if (!body) return;
    this.inputContent.value = "";
    this.sendMsg(body).catch(() => {});
  }

  handleSendOk(resp) {
    var msgItem = document.createElement("p");
    msgItem.className = "text-blue-600 font-medium";
    msgItem.innerText = "我: " + resp.body;
    this.htmlMsg.appendChild(msgItem);
    this.htmlMsg.scrollTop = this.htmlMsg.scrollHeight;
  }

  appendMsg(dir, payload) {
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

  appendSystemMsg(text, className) {
    if (!this.htmlMsg) return;
    var item = document.createElement("p");
    item.className = "text-center text-xs italic text-base-content/40 " + (className || "");
    item.innerText = text;
    this.htmlMsg.appendChild(item);
    this.htmlMsg.scrollTop = this.htmlMsg.scrollHeight;
  }
}

export default ChatRoom;
```

chat/user_socket.js

```javascript
import { Socket } from "phoenix";

class UserSocket {
  constructor() {
    this.socket = null;
  }

  connect() {
    return new Promise((resolve, reject) => {
      if (this.socket && this.socket.isConnected()) {
        resolve(this.socket);
        return;
      }
      this.socket = new Socket("/socket", { params: {} });
      this.socket.onError((err) => reject(err));
      this.socket.onOpen(() => resolve(this.socket));
      this.socket.connect();
    });
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }
}

export default UserSocket;
```
