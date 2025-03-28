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
    Logger.debug("on new_msg")
    broadcast!(socket, "resp_msg", %{body: body})
    {:noreply, socket}
  end
end
```

### html

```html
<input id="chat-input" type="text" />
<div id="messages"></div>
```

### js

js 和 ts 二选一

#### javascript

user_socket.js

```javascript
import { Socket } from "phoenix";

let socket = new Socket("/socket", { params: { token: window.userToken } });
socket.connect();

let channel = socket.channel("room:lobby", {});
channel
  .join()
  .receive("ok", (resp) => {
    console.log("Joined successfully", resp);
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

let chatInput = document.querySelector("#chat-input");
let msgInHtml = document.querySelector("#messages");

chatInput.addEventListener("keypress", (event) => {
  if (event.key === "Enter") {
    channel.push("client_msg", { body: chatInput.value });
    chatInput.value = "";
  }
});

channel.on("resp_msg", (payload) => {
  let messageItem = document.createElement("p");
  messageItem.innerText = `on resp_msg ${payload.body}`;
  msgInHtml.appendChild(messageItem);
});

export default socket;
```

app.js

```javascript
import "./user_socket.js";
```

#### typescript

```sh
npm install phoenix
```

user_socket.ts

```typescript
import { Socket, Channel } from "phoenix";

type MsgPayload = {
  body: string;
};

type JoinResponse = {
  status: string;
};

export class ChatSocket {
  private socket: Socket;
  private channel: Channel | null = null;
  private chatInput: HTMLInputElement | null = null;
  private msgInHtml: HTMLElement | null = null;

  constructor() {
    this.socket = new Socket("/socket", { params: { token: window.userToken } });
  }

  private prepare(): void {
    this.socket.connect();
    this.chatInput = document.querySelector("#chat-input");
    this.msgInHtml = document.querySelector("#messages");

    if (this.chatInput) {
      this.chatInput.addEventListener("keypress", this.onKeyPress.bind(this));
    }
  }

  public enterRoom(roomName: string): Promise<JoinResponse> {
    return new Promise((resolve, reject) => {
      this.channel = this.socket.channel(roomName, {});

      this.channel
        .join()
        .receive("ok", (resp: JoinResponse) => {
          console.log("Joined successfully", resp);
          this.setMsgHandlers();
          resolve(resp);
        })
        .receive("error", (resp: JoinResponse) => {
          console.log("Unable to join", resp);
          reject(resp);
        });
    });
  }

  private setMsgHandlers(): void {
    if (!this.channel) return;

    this.channel.on("resp_msg", (payload: MsgPayload) => {
      this.onMsg(payload);
    });
  }

  public sendMsg(message: string): void {
    if (!this.channel) {
      console.error("Not connected to a channel");
      return;
    }

    this.channel.push("client_msg", { body: message });
  }

  private onMsg(payload: MsgPayload): void {
    if (!this.msgInHtml) return;

    const messageItem = document.createElement("p");
    messageItem.innerText = `on resp_msg ${payload.body}`;
    this.msgInHtml.appendChild(messageItem);
  }

  private onKeyPress(event: KeyboardEvent): void {
    if (!this.chatInput) return;

    if (event.key === "Enter") {
      this.sendMsg(this.chatInput.value);
      this.chatInput.value = "";
    }
  }
}

export default ChatSocket;
```

app.js

```javascript
import ChatSocket from "./user_socket.js";

document.addEventListener("DOMContentLoaded", (event) => {
  console.log(window.location.pathname);
  if (window.location.pathname === "/") {
    const chat = new ChatSocket();
    chat.prepare();
    chat.enterRoom("room:lobby");
  }
});
```
