# websocket

不使用 channel 来操作 websocket

## 步骤

### 注册路由

```sh
lib/web_demo_web/endpoint.ex
```

```elixir
socket("/demo", DemoSocket,
  websocket: true,
  longpoll: false
)
```

### 代码

```sh
lib/web_demo_web/socket/demo_socket.ex
```

```elixir
defmodule DemoSocket do
  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(state) do
    {:ok, state}
  end

  def init(state) do
    IO.puts("connect pid is #{inspect(self())}")
    send(self(), {:aaa})
    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    IO.puts("handle_in text is #{inspect(text)}")
    {:reply, :ok, {:text, text}, state}
  end

  def handle_info(_AAA, state) do
    IO.puts("handle_info state is #{inspect(state)}")
    pid_info = "#{inspect(self())}"
    {:push, {:text, pid_info}, state}
    # {:ok, state}
  end

  def terminate(reason, _state) do
    IO.puts("terminate reason is #{inspect(reason)}")
    :ok
  end
end
```

### 查看路由表

```sh
mix phx.routes
```
