# websocket

## 说明

不使用 channel 来操作 websocket

## 例子

### 创建

```sh
mix phx.new web_demo --no-ecto --no-assets --no-gettext --no-dashboard --no-live --no-mailer
```

### 路由

```sh
lib/web_demo_web/endpoint.ex
```

```elixir
socket "/demo", DemoSocket,
  websocket: [path: "/aaa"],
  longpoll: false
```

### websocket 服务端

demo_channel.ex

```elixir
defmodule DemoChannel do
  require Logger

  def run do
    Logger.debug("on DemoChannel run")
  end
end
```

demo_socket.ex

```elixir
defmodule DemoSocket do
  @behaviour Phoenix.Socket.Transport
  require Logger

  # 服务端启动以后，会被调用
  # def child_spec(opts) do
  #   Logger.debug("on child_spec opts #{inspect(opts)}")
  #   :ignore
  # end

  # 服务端启动以后，会被调用
  def child_spec(opts) do
    Logger.debug("on child_spec opts #{inspect(opts)}")

    %{
      id: __MODULE__,
      start: {Task, :start_link, [&DemoChannel.run/0]},
      restart: :transient
    }
  end

  def connect(state) do
    Logger.debug("on connect pid #{inspect(self())}")
    {:ok, state}
  end

  def init(state) do
    Logger.debug("on init pid #{inspect(self())}")
    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    Logger.debug("on handle_in text #{inspect(text)}")
    {:reply, :ok, {:text, text}, state}
  end

  def handle_info(_AAA, state) do
    Logger.debug("on handle_info state #{inspect(state)}")
    pid_info = "#{inspect(self())}"
    {:push, {:text, pid_info}, state}
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.debug("on terminate reason #{inspect(reason)}")
    :ok
  end
end
```

### 查看路由

显示的 path 是错的，不知道怎么改

```sh
mix phx.routes
```

## 测试

### deps

```elixir
{:websockex, "~> 0.4.3"}
```

### 客户端代码

```elixir
defmodule WebSocketClient do
  require Logger
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :ok)
  end

  def send_message(pid, message) do
    WebSockex.send_frame(pid, {:text, message})
  end

  def handle_connect(_conn, state) do
    Logger.debug("client connected to the websocket server")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    Logger.debug("client received message: #{msg}")
    {:ok, state}
  end

  def handle_disconnect(_conn, state) do
    Logger.debug("disconnected from the websocket server")
    {:ok, state}
  end
end
```

```elixir
defmodule WebDemo do
  require Logger

  def demo do
    {:ok, pid} = WebSocketClient.start_link("ws://localhost:4000/demo/aaa")
    WebSocketClient.send_message(pid, "Hello, server!")
  end
end
```
