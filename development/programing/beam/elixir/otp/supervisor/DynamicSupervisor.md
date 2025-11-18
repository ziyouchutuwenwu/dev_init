# DynamicSupervisor

## 说明

按需创建子进程，相当于 `erlang` 的 `simple_one_for_one`

[参考文档](https://elixirschool.com/zh-hans/lessons/advanced/otp-supervisors/#%E5%8F%97%E7%9B%91%E7%AE%A1%E7%9A%84-tasks)

## 例子

### 定义 supervisor

demo_sup.ex

```elixir
defmodule DemoSup do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg1, init_arg2) do
    DynamicSupervisor.start_link(__MODULE__, [init_arg1, init_arg2], name: __MODULE__)
  end

  def start_child(child_arg1, child_arg2) do
    child_spec = %{
      id: DemoChild,
      start: {DemoChild, :start_link, [child_arg1, child_arg2]},
      shutdown: 5000,
      restart: :transient,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init([extra_arg1, extra_arg2]) do
    Logger.debug("on DynamicSupervisor init #{extra_arg1} #{extra_arg2}")

    DynamicSupervisor.init(
      strategy: :one_for_one,

      # 在 max_seconds 内，所有子进程加起来的最大的重启次数超过 max_restarts，所有子进程都会以 shutdown 的原因被杀掉
      # 并且 supervisor 也会被杀掉
      max_restarts: 10,
      max_seconds: 3600,
      # 子进程数量不能超过这些，多余的忽略
      max_children: 5,

      # 加上这行，就和 erlang一样，在 sup 执行 start_child 的时候，会把参数一起带过去，类似 extra_arg1, extra_arg2, child_arg1, child_arg2
      extra_arguments: [extra_arg1, extra_arg2]
    )
  end
end
```

### 定义子进程

demo_child.ex

```elixir
defmodule DemoChild do
  use GenServer
  require Logger

  def start_link(extra_arg1, extra_arg2, child_arg1, child_arg2) do
    Logger.debug("on gen_server child start_link #{extra_arg1} #{extra_arg2} #{child_arg1} #{child_arg2}")
    GenServer.start_link(__MODULE__, {extra_arg1, extra_arg2, child_arg1, child_arg2}, name: __MODULE__)
  end

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

  def queue do
    GenServer.call(__MODULE__, :queue)
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end
end
```

或者

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

## 测试

`gen_server` 子进程测试

```elixir
DemoSup.start_link("aaa", "bbb")
Supervisor.which_children(DemoSup)
{:ok, pid} = DemoSup.start_child("ccc", "ddd")
Supervisor.which_children(DemoSup)
DemoChild.queue
```

普通子进程测试

```elixir
DemoSup.start_link("aaa", "bbb")
Supervisor.which_children(DemoSup)

# 子进程个数限制为5个
list = 1..10 |> Enum.to_list()

list
|> Enum.each(fn index ->
  DemoSup.start_child("c#{inspect(index)}", "d#{inspect(index)}")
end)

Supervisor.which_children(DemoSup)
```

修改 `pid`

```elixir
Process.exit(pid("0.160.0"), :shutdown)
Supervisor.which_children(DemoSup)
```
