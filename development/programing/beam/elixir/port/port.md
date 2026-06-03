# port

## 说明

```sh
{:spawn, command}
  通过默认 shell, 关闭的时候，可能导致僵尸进程

{:spawn_executable, path}
  不经过 shell, 需要明确可执行文件的路径
```

## 用法

```elixir
defmodule PortDemo do
  use GenServer
  require Logger

  def start_link(file_path) do
    {:ok, pid} = GenServer.start_link(__MODULE__, file_path, name: __MODULE__)
    Logger.debug("gen_server pid is #{inspect(pid)}")
    {:ok, pid}
  end

  def is_alive(timeout \\ 5000) do
    GenServer.call(__MODULE__, {:is_alive}, timeout)
  end

  def do_demo(data, timeout \\ 10000) do
    GenServer.call(__MODULE__, {:do_demo, data, timeout}, timeout + 100)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  # 注意这里的参数
  def init(file_path) do
    port =
      Port.open(
        {:spawn_executable, file_path},
        [
          :binary,
          :exit_status,
          args: ["-u"]
        ]
      )

    {:ok, {port, nil}}
  end

  def handle_call({:is_alive}, _from, {port, _pending} = state) do
    is_alive = not is_nil(Port.info(port))
    {:reply, is_alive, state}
  end

  # 在 handle_info 里面 GenServer.reply
  def handle_call({:do_demo, data, timeout}, from, {port, nil}) do
    timer_ref = Process.send_after(self(), :port_timeout, timeout)
    Port.command(port, data)
    {:noreply, {port, {from, timer_ref}}}
  end

  # 此时 do_demo 还没完成，拒绝回复
  def handle_call({:do_demo, _data, _timeout}, _from, {_port, {_pending_from, _timer_ref}} = state) do
    Logger.warning("handle_call do_demo busy")
    {:reply, {:error, :busy}, state}
  end

  # 协议处理
  def handle_info({port, {:data, bin_data}}, {port, {from, timer_ref}}) do
    Process.cancel_timer(timer_ref)
    result =
      try do
        case :erlang.binary_to_term(bin_data, [:safe]) do
          {:ok, data} ->
            data

          other ->
            {:error, {:unexpected_term, other}}
        end
      rescue
        _ -> {:error, :bad_format}
      end

    Logger.debug("handle_info {:data, bin_data}")
    GenServer.reply(from, result)
    {:noreply, {port, nil}}
  end

  def handle_info({port, {:exit_status, status}}, {port, {from, timer_ref}}) do
    Process.cancel_timer(timer_ref)
    GenServer.reply(from, {:error, {:port_exit, status}})
    {:stop, :normal, {port, nil}}
  end

  def handle_info({port, {:data, bin_data}}, {port, nil}) do
    Logger.warning("unexpected port data while idle: #{inspect(bin_data, limit: 200)}")
    {:noreply, {port, nil}}
  end

  def handle_info({port, {:exit_status, status}}, {port, nil}) do
    Logger.warning("port exited unexpectedly (status=#{status}) while idle")
    {:stop, :normal, {port, nil}}
  end

  def handle_info(:port_timeout, {port, {from, _timer_ref}}) do
    Logger.warning("port operation timed out")
    GenServer.reply(from, {:error, :timeout})
    {:stop, :normal, {port, nil}}
  end

  def handle_info(:port_timeout, {port, nil}) do
    Logger.warning("stale timeout received while idle")
    {:noreply, {port, nil}}
  end

  def terminate(reason, {port, _pending}) do
    Port.close(port)
    Logger.info("port terminated: #{inspect(reason)}")
  end
end
```

```elixir
defmodule PortSup do
  use Supervisor

  def start_link(file_path) do
    Supervisor.start_link(__MODULE__, [file_path], name: __MODULE__)
  end

  def init([file_path]) do
    children = [
      %{
        id: PortDemo,
        start: {PortDemo, :start_link, [file_path]},
        restart: :transient
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

```elixir
defmodule Demo do
  require Logger

  def demo do
    bin_file = System.find_executable("cat")
    PortSup.start_link(bin_file)
    is_alive = PortDemo.is_alive()
    Logger.debug("is_alive: #{is_alive}")

    result = PortDemo.do_demo(:erlang.term_to_binary({:ok, "111111111111111111111111111111"}))
    Logger.debug("do_demo result: #{inspect(result)}")

    task1 =
      Task.async(fn ->
        result = PortDemo.do_demo(:erlang.term_to_binary({:ok, "222222222222222222222222222222"}))
        Logger.warning("task1 result: #{inspect(result)}")
      end)

    task2 =
      Task.async(fn ->
        result = PortDemo.do_demo(:erlang.term_to_binary({:ok, "333333333333333333333333333333"}))
        Logger.warning("task2 result: #{inspect(result)}")
      end)

    Task.await(task1)
    Task.await(task2)

    PortDemo.stop()
  end
end
```
