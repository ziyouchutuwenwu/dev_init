# PartitionedSupervisor

## 说明

把多个 supervisor 绑定到 cpu 的不同的逻辑核上

## 例子

### 类似进程池

demo_sup.ex

```elixir
defmodule DemoSup do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      {
        PartitionSupervisor,
        child_spec: LogWorker,
        name: DemoLogPool,
        partitions: System.schedulers_online(),
        with_arguments: fn _args, partition ->
          [partition]
        end
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

log_worker.ex

```elixir
defmodule LogWorker do
  use GenServer
  require Logger

  def start_link(shard_index) do
    GenServer.start_link(__MODULE__, shard_index)
  end

  @impl true
  def init(shard_index) do
    Logger.debug("LogWorker init #{inspect(shard_index)}")
    {:ok, shard_index}
  end

  @impl true
  def handle_cast({:process_log, device_id, msg}, shard_index) do
    Logger.debug("[分片 #{shard_index}] 处理设备 #{device_id} 的消息: #{msg}")
    {:noreply, shard_index}
  end
end
```

log_sender.ex

```elixir
defmodule LogSender do
  def log(device_id, message) do
    target = {:via, PartitionSupervisor, {DemoLogPool, device_id}}
    GenServer.cast(target, {:process_log, device_id, message})
  end
end
```

demo.ex

```elixir
defmodule Demo do
  def demo do
    DemoSup.start_link()
    LogSender.log(4, "测试人造人四号")
  end
end
```

### 绑定 DynamicSupervisor

demo_sup.ex

```elixir
defmodule DemoSup do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init([init_arg1, init_arg2]) do
    children = [
      {
        PartitionSupervisor,
        child_spec: {SubSup, {init_arg1, init_arg2}}, name: DemoPartitionSup
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

sub_sup.ex

```elixir
defmodule SubSup do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    {extra_arg1, extra_arg2} = init_arg
    # 这里不注册固定的 name
    DynamicSupervisor.start_link(__MODULE__, [extra_arg1, extra_arg2])
  end

  def start_child(partition_key, child_arg1, child_arg2) do
    child_spec = %{
      id: DemoChild,
      start: {DemoChild, :start_link, [child_arg1, child_arg2]},
      shutdown: 5000,
      restart: :transient,
      type: :worker
    }

    # 相同的 partition_key 会路由到同一个 DynamicSupervisor
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {DemoPartitionSup, partition_key}},
      child_spec
    )
  end

  @impl true
  def init([extra_arg1, extra_arg2]) do
    Logger.debug("on DynamicSupervisor init #{extra_arg1} #{extra_arg2}")

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [extra_arg1, extra_arg2]
    )
  end
end
```

demo_child.ex

```elixir
defmodule DemoChild do
  require Logger

  def start_link(extra_arg1, extra_arg2, child_arg1, child_arg2) do
    Logger.debug(
      "on child start_link #{extra_arg1} #{extra_arg2} #{child_arg1} #{child_arg2}"
    )

    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    Process.sleep(5 * 1000)
    Logger.debug("timeout reached")
  end
end
```

demo.ex

```elixir
defmodule Demo do
  require Logger

  def demo do
    Demo.start_partition_sup()
    Demo.start_workers()
    Demo.show_partitions()
  end

  def start_partition_sup do
    DemoSup.start_link([:arg1, :arg2])
  end

  def start_workers do
    keys = [:part_1, :part_2, :part_3, :part_4, :part_5, :part_6]

    Enum.map(keys, fn key ->
      SubSup.start_child(key, "child1", "child2")
    end)
  end

  def show_partitions do
    partition_count = System.schedulers_online()
    Logger.debug("Partition 数量: #{partition_count}")

    Enum.each(0..(partition_count - 1), fn partition ->
      children =
        DynamicSupervisor.count_children(
          {:via, PartitionSupervisor, {DemoPartitionSup, partition}}
        )

      Logger.debug("partition #{partition}: #{inspect(children)}")
    end)
  end
end
```
