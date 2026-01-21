# horde

## 说明

进程在集群内某个节点注册，此节点挂掉以后，进程会在其他节点上自动重启

在任意节点注册，自动调度到某个节点执行

## 用法

### 代码

```elixir
defmodule Demo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 分布式 Registry
      {Horde.Registry, [name: Demo.HordeRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [name: Demo.HordeSupervisor, strategy: :one_for_one, members: :auto]},

      # 如果用 libcluster， 则要比 Horde 晚启动
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Demo.Worker do
  require Logger

  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: via(arg))
  end

  def via(name) do
    {:via, Horde.Registry, {Demo.HordeRegistry, name}}
  end

  def init(arg) do
    Logger.debug("[#{node()}] Worker started: #{inspect(arg)}")
    {:ok, arg}
  end
end

defmodule Demo do
  def create(name) do
    Horde.DynamicSupervisor.start_child(Demo.HordeSupervisor, {Demo.Worker, name})
  end

  def get(name) do
    Horde.Registry.lookup(Demo.HordeRegistry, name)
  end

  def get_all do
    Horde.Registry.select(Demo.HordeRegistry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  def stop(name) do
    case Horde.Registry.lookup(Demo.HordeRegistry, name) do
      [{pid, _}] ->
        Horde.DynamicSupervisor.terminate_child(Demo.HordeSupervisor, pid)

      [] ->
        {:error, :not_found}
    end
  end
end
```

### 测试

```shell
iex --name aaa@127.0.0.1 --cookie 123456 -S mix
iex --name bbb@127.0.0.1 --cookie 123456 -S mix
```
