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

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, nil}
  end

  # 直接返回
  def handle_call(:aaa_call, _from, state) do
    {:reply, :ok, state}
  end

  # 异步，不直接返回
  def handle_call({:bbb_call, _data}, from, nil) do
    Process.send(self(), :bbb, [])
    {:noreply, from}
  end

  def handle_cast({:ccc, msg}, state) do
    Logger.debug("cast ccc: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(:ddd, state) do
    Logger.debug("handle_info ddd")
    {:noreply, state}
  end

  # bbb 正常返回
  def handle_info(:bbb, {_pid, _ref} = from) do
    Logger.debug("bbb done")
    GenServer.reply(from, :ok)
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
    {:ok, pid} = GenServerDemo.start_link()

    a = GenServer.call(pid, :aaa_call)
    Logger.debug("call aaa_call -> #{inspect(a)}")

    b = GenServer.call(pid, {:bbb_call, "bbb msg"})
    Logger.debug("call bbb_call -> #{inspect(b)}")

    c = GenServer.cast(pid, {:ccc, "ccc msg"})
    Logger.debug("cast ccc -> #{inspect(c)}")

    d = send(pid, :ddd)
    Logger.debug("send ddd -> #{inspect(d)}")
  end
end
```
