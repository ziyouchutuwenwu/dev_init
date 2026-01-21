# supervisor

## 例子

单个 task

```elixir
defmodule Task1 do
  require Logger
  @name :xxx

  # 异步, task 崩溃不影响 supervisor
  def async do
    Task.Supervisor.start_link(name: @name)

    @name
    |> Task.Supervisor.start_child(fn ->
      my_task()
    end)
  end

  # task 一旦崩溃，supervisor 也会出问题
  def wait do
    Task.Supervisor.start_link(name: @name)

    @name
    |> Task.Supervisor.async(fn ->
      my_task()
    end)
    |> Task.await()
  end

  # task 崩溃, supervisor 不受影响
  def nolink_wait do
    Task.Supervisor.start_link(name: @name)

    task =
      @name
      |> Task.Supervisor.async_nolink(fn ->
        my_task()
      end)

    # 看超时时间内的结果
    case task |> Task.yield(3000) do
      {:ok, result} ->
        Logger.debug("result: #{result}")

      _ ->
        Logger.debug("result timed out")
        task |> Task.shutdown()
    end
  end

  defp my_task do
    Logger.debug("111111111")
    :timer.sleep(2000)
    Logger.debug("2222222222")
  end
end
```

多个 task

```elixir
defmodule Task2 do
  require Logger
  @name :xxx

  def wait_one() do
    Task.Supervisor.start_link(name: @name)

    @name
    |> Task.Supervisor.async(fn ->
      Logger.debug("in task2 progress")
    end)
    |> Task.await()
  end

  def wait_many do
    {:ok, pid} = Task.Supervisor.start_link(strategy: :one_for_one)

    tasks = [
      Task.Supervisor.async_nolink(pid, fn ->
        {:task1, "result1"}
      end),
      Task.Supervisor.async_nolink(pid, fn ->
        {:task2, "result2"}
      end),
      Task.Supervisor.async_nolink(pid, fn ->
        {:task3, "result3"}
      end)
    ]

    tasks
    |> Enum.map(fn task ->
      Task.await(task, :infinity)
    end)
  end
end
```
