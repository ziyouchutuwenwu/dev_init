# websocket

## 说明

无 channel 的 websocket

## 例子

### 创建

```sh
mix phx.new web_demo --no-ecto --no-assets --no-gettext --no-dashboard --no-live --no-mailer
```

### endpoint

endpoint.ex

```elixir
 # 会往路由表里注册
# 默认是 /demo/websocket, 改成 /demo/aaa
socket "/demo", DemoSocket,
  websocket: [
    path: "/aaa",
    connect_info: [:x_headers, :uri, :peer_data, session: @session_options]
  ],
  longpoll: false
```

### 代码

demo_socket.ex

```elixir
defmodule DemoSocket do
  require Logger

  def connect(state) do
    Logger.debug("on connect #{inspect(self())}")
    {:ok, state}
  end

  def init(state) do
    Logger.debug("on init #{inspect(self())}")
    {:ok, state}
  end

  # 处理 websocket 客户端消息
  def handle_in({text, _opts}, state) do
    Logger.debug("on handle_in text #{inspect(text)}")
    {:reply, :ok, {:text, text}, state}
  end

  # 处理进程消息
  def handle_info(_AAA, state) do
    Logger.debug("on handle_info state #{inspect(state)} #{inspect(self())}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.debug("on terminate reason #{inspect(reason)}")
    :ok
  end
end
```

### 路由

endpoint 里修改了 websocket 的 path, 这里显示是错的

```sh
mix phx.routes
```

### 测试

```sh
npm install -g wscat
wscat -c ws://localhost:4000/demo/aaa
```
