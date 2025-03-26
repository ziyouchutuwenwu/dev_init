# channel

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
let messagesContainer = document.querySelector("#messages");

chatInput.addEventListener("keypress", (event) => {
  if (event.key === "Enter") {
    channel.push("client_msg", { body: chatInput.value });
    chatInput.value = "";
  }
});

channel.on("resp_msg", (payload) => {
  let messageItem = document.createElement("p");
  messageItem.innerText = `on resp_msg ${payload.body}`;
  messagesContainer.appendChild(messageItem);
});

export default socket;
```

app.js

```javascript
import "./user_socket.js";
```
