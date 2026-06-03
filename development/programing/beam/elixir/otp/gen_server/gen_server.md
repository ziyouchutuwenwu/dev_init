# gen_server

## 说明

```sh
call  可以同步返回，可以异步返回
cast  只能异步
info  只能异步
```

## 代码

```elixir
defmodule GenServerDemo do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # 直接返回
  def handle_call(:aaa, _from, state) do
    Logger.debug("on call aaa")
    {:reply, 111, state}
  end

  # 异步，不直接返回
  def handle_call({:bbb, _data}, from, _state) do
    Logger.debug("on call bbb")
    Process.send(self(), :bbb, [])
    {:noreply, from}
  end

  def handle_cast({:ccc, msg}, state) do
    Logger.debug("on handle_cast ccc #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(:ddd, state) do
    Logger.debug("on handle_info ddd")
    {:noreply, state}
  end

  # bbb 正常返回
  def handle_info(:bbb, {_pid, _ref} = from) do
    Logger.debug("on handle_info bbb")
    GenServer.reply(from, 222)
    {:noreply, nil}
  end

  # 默认正常
  def handle_info(:bbb, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
```

demo.ex

```elixir
defmodule Demo do
  require Logger

  def demo do
    GenServerDemo.start_link()

    GenServer.call(GenServerDemo, :aaa)
    GenServer.call(GenServerDemo, {:bbb, "msg"})
    GenServer.cast(GenServerDemo, {:ccc, "msg"})
    send(GenServerDemo, :ddd)
  end
end
```
