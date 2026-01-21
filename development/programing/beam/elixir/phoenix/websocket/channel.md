# channel

## 说明

封装过的 websocket

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-ecto --no-gettext --no-dashboard --no-live --no-mailer
```

### user_socket

```sh
mix phx.gen.socket User
```

### room_channel

```sh
mix phx.gen.channel Room
```

user_socket.ex 去掉如下注释

```elixir
channel "room:*", WebDemoWeb.RoomChannel
```

room_channel.ex

```elixir
defmodule WebDemoWeb.RoomChannel do
  use WebDemoWeb, :channel
  require Logger

  @impl true
  def join("room:lobby", _message, socket) do
    Logger.debug("on join room lobby")
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def handle_in("client_msg", %{"body" => body}, socket) do
    Logger.debug("on client_msg")
    broadcast!(socket, "room_msg", %{body: body})
    {:noreply, socket}
  end


  # 这里要写，不然不拦截
  intercept ["room_msg"]

  @impl true
  def handle_out("room_msg", payload, socket) do
    Logger.debug("拦截返回客户端的消息 #{inspect(payload)}")
    push(socket, "room_msg", %{body: "11111111111111111"})
    {:noreply, socket}
  end
end
```

### html

```html
<div class="flex flex-col md:flex-row items-center p-4 gap-4">
  <div class="flex flex-col space-y-4 w-full md:w-auto">
    <p class="text-sm text-center text-gray-600">room 信息</p>
    <div class="flex space-x-2">
      <button id="enter-room" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors h-10">
        进入
      </button>
      <button id="leave-room" class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition-colors h-10">
        离开
      </button>
    </div>
    <div id="room-msg" class="flex-1 overflow-auto p-2"></div>
  </div>
  <div class="px-40 flex-1 flex flex-col">
    <input
      id="chat-input"
      type="text"
      class="w-full h-10 px-2 border-b border-gray-300 focus:outline-none"
      placeholder="输入消息..."
    />
    <div id="msg" class="flex-1 overflow-auto p-2"></div>
  </div>
</div>
```

### js

user_socket.js

```javascript
import { Socket } from "phoenix";

let socket = new Socket("/socket", { params: { token: window.userToken } });
let channel = socket.channel("room:lobby", {});

let enterRoom = document.querySelector("#enter-room");
let leaveRoom = document.querySelector("#leave-room");
let roomMsg = document.querySelector("#room-msg");

let inputContent = document.querySelector("#chat-input");
let htmlMsg = document.querySelector("#msg");

socket.connect();

enterRoom.addEventListener("click", () => {
  channel.join().receive("ok", (resp) => {
    console.log("Joined successfully", resp);
    let msgItem = document.createElement("p");
    msgItem.innerText = `成功加入房间`;
    roomMsg.appendChild(msgItem);
  });
});

leaveRoom.addEventListener("click", () => {
  channel.leave().receive("ok", () => {
    console.log("Left the channel successfully");
    let msgItem = document.createElement("p");
    msgItem.innerText = `离开房间`;
    roomMsg.appendChild(msgItem);
  });
});

inputContent.addEventListener("keypress", (event) => {
  if (event.key === "Enter") {
    channel.push("client_msg", { body: inputContent.value });
    inputContent.value = "";
  }
});

channel.on("room_msg", (payload) => {
  let msgItem = document.createElement("p");
  msgItem.innerText = `on room_msg ${payload.body}`;
  htmlMsg.appendChild(msgItem);
});

export default socket;
```

app.js

```javascript
import "./user_socket.js";
```
