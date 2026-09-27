# sched_ex

## 说明

定时任务

## 例子

依赖

```elixir
{:sched_ex, "~> 1.0"}
```

代码

```elixir
defmodule Demo do
  require Logger

  def demo do
    # 指定时间
    SchedEx.run_at(&on_at_task/0, Timex.shift(Timex.now("Asia/Shanghai"), minutes: 1))

    # 每隔 30s 执行一次
    SchedEx.run_every(&on_every_task/0, "*/30 * * * * * *")

    # 延迟 xx ms 执行一次
    SchedEx.run_in(&on_in_task/0, 5000)
  end

  defp on_at_task do
    Logger.debug("run_at")
  end

  defp on_every_task do
    Logger.debug("run_every")
  end

  defp on_in_task do
    Logger.debug("run_in")
  end
end
```
