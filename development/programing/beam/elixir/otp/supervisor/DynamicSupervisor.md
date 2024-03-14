# DynamicSupervisor

## 说明

按需创建子进程的 `supervisor`, 子进程创建策略只支持 `one_for_one`

相当于 `erlang` 的 `simple_one_for_one`

[参考文档](https://elixirschool.com/zh-hans/lessons/advanced/otp-supervisors/#%E5%8F%97%E7%9B%91%E7%AE%A1%E7%9A%84-tasks)

## 代码

### 定义 supervisor

demo_sup.ex

```elixir
defmodule DemoSup do
  use DynamicSupervisor

  def start_link(init_arg1, init_arg2) do
    DynamicSupervisor.start_link(__MODULE__, [init_arg1, init_arg2], name: __MODULE__)
  end

  def start_child(child_arg1, child_arg2) do
    child_spec = %{
      id: SimpleQueue,
      start: {SimpleQueue, :start_link, [child_arg1, child_arg2]},
      shutdown: 5000,
      restart: :permanent,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init([extra_arg1, extra_arg2]) do
    IO.puts("on DynamicSupervisor init #{extra_arg1} #{extra_arg2}")

    DynamicSupervisor.init(
      strategy: :one_for_one,

      # 在 max_seconds 内，所有子进程加起来的最大的重启次数超过 max_restarts，所有子进程都会以 shutdown 的原因被杀掉
      # 并且 supervisor 也会被杀掉
      max_restarts: 10,
      max_seconds: 3600,
      max_children: 100,

      # 加上这行，就和 erlang一样，在 sup 执行 start_child 的时候，会把参数一起带过去，类似 extra_arg1, extra_arg2, child_arg1, child_arg2
      extra_arguments: [extra_arg1, extra_arg2]
    )
  end
end
```

### 定义子进程

simple_queue.ex

```elixir
defmodule SimpleQueue do
  use GenServer

  def start_link(extra_arg1, extra_arg2, child_arg1, child_arg2) do
    IO.puts("on gen_server child start_link #{extra_arg1} #{extra_arg2} #{child_arg1} #{child_arg2}")
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
defmodule SimpleQueue do
  def start_link(extra_arg1, extra_arg2, child_arg1, child_arg2) do
    IO.puts("on simple child start_link #{extra_arg1} #{extra_arg2} #{child_arg1} #{child_arg2}")
    pid = spawn(__MODULE__, :loop, [extra_arg1, extra_arg2])
    {:ok, pid}
  end

  def loop(extra_arg1, extra_arg2) do
    receive do
      _msg ->
        IO.puts("received msg #{extra_arg1} #{extra_arg2}")
    end
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
SimpleQueue.queue
```

普通子进程测试

```elixir
DemoSup.start_link("aaa", "bbb")
Supervisor.which_children(DemoSup)
{:ok, pid} = DemoSup.start_child("ccc", "ddd")
Supervisor.which_children(DemoSup)
send(pid, {:hello, "world"})
```

修改 `pid`

```elixir
Process.exit(pid("0.160.0"), :shutdown)
Supervisor.which_children(DemoSup)
```
