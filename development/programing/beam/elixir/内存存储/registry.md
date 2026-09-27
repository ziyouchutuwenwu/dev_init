# registry

## 说明

进程死亡以后，registry 会自动清理进程 pid 相关的所有记录

## 例子

```elixir
defmodule DemoSup do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      %{
        id: DemoRegistry,
        # partitions 是在 cpu 的多个逻辑核上跑多个 Registry
        start: {Registry, :start_link, [[keys: :unique, name: DemoRegistry, partitions: System.schedulers_online()]]},
        restart: :transient
      }
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
```

```elixir
defmodule Demo do
  require Logger

  def demo do
    DemoSup.start_link()
    {:ok, _} = Registry.register(DemoRegistry, "key1", "value1")
    [{pid, value}] = Registry.lookup(DemoRegistry, "key1")

    Logger.debug("value: #{inspect(value)}")
    Logger.debug("pid: #{inspect(pid)}")
  end
end
```
