# 通用 supervisor

子进程自动创建

手动创建子进程的为 [DynamicSupervisor](https://elixirschool.com/en/lessons/advanced/otp-supervisors/#configuration)

## 说明

start_link 返回的是父进程 pid

## 代码

如果需要多种子进程, 直接在 `children` 数组里面添加即可

### 定义 supervisor

demo_sup.ex

```elixir
defmodule DemoSup do
  use Supervisor

  def start_link(init_arg1, init_arg2) do
    Supervisor.start_link(__MODULE__, [init_arg1, init_arg2], name: __MODULE__)
  end

  def init([init_arg1, init_arg2]) do
    children = [
      %{
        id: DemoServer,
        start: {DemoServer, :start_link, [init_arg1, init_arg2]},
        restart: :transient
        # type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # 如果 restart 的方式不是 permanent，如果需要手动启动子进程，可以添加这个
  # def start_child(init_arg1, init_arg2) do
  #   child_spec = %{
  #     id: DemoServer,
  #     start: {DemoServer, :start_link, [init_arg1, init_arg2]},
  #     restart: :transient,
  #     type: :worker
  #   }

  #   Supervisor.start_child(__MODULE__, child_spec)
  # end
end
```

### 定义子进程

demo_server.ex

```elixir
defmodule DemoServer do
  use GenServer
  require Logger

  def start_link(init_arg1, init_arg2) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {init_arg1, init_arg2}, name: __MODULE__)
    Logger.debug("gen_server pid is #{inspect(pid)}")
    {:ok, pid}
  end

  def queue do
    GenServer.call(__MODULE__, :queue)
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def async_stop do
    GenServer.cast(__MODULE__, :stop)
  end

  # -----------------------------------------------------------------
  def init(state) do
    {:ok, state}
  end

  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:dequeue, _from, []) do
    {:reply, nil, []}
  end

  def handle_call(:queue, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, "server stopped", state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, _state) do
    IO.inspect("reason #{inspect(reason)} in terminate")
  end
end
```

或者

```elixir
defmodule DemoServer do
  require Logger

  def start_link(init_arg1, init_arg2) do
    pid = spawn_link(__MODULE__, :loop, [init_arg1, init_arg2])
    {:ok, pid}
  end

  def loop(init_arg1, init_arg2) do
    receive do
      _msg ->
        Logger.debug("received msg #{init_arg1} #{init_arg2}")
    end
  end
end
```

## 测试

demo.ex

```elixir
defmodule Demo do
  def start do
    DemoSup.start_link(111, 222)
  end

  def queue do
    DemoServer.queue()
  end

  def dequeue do
    DemoServer.dequeue()
  end

  def close do
    DemoServer.stop()
    # 删除之前，server必须停止，所以，只能用同步的stop
    Supervisor.delete_child(DemoSup, DemoServer)
  end

  # def start_child do
  #   DemoSup.start_child(333, 444)
  # end

  def debug do
    Supervisor.which_children(DemoSup)
  end
end
```
