# highlander

## 说明

分布式 global, 强一致。

多节点竞争的话，保留第一个节点，新的会被杀掉

## 用法

```elixir
{:highlander, "~> 0.2.1"}
```

```elixir
defmodule Demo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Highlander, Demo.Worker}
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Demo.Worker do
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: Demo.Worker)
  end

  @impl true
  def init(arg) do
    Process.flag(:trap_exit, true)
    Logger.debug("[#{node()}] worker started, pid: #{inspect(self())}")
    {:ok, %{arg: arg, started_at: DateTime.utc_now()}}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.debug("[#{node()}] worker stopped, pid: #{inspect(self())}")
  end
end


defmodule Demo do
  def demo do
    case Process.whereis(Demo.Worker) do
      nil -> {:error, :worker_not_started}
      pid -> {:ok, %{pid: pid, node: node()}}
    end
  end
end
```
