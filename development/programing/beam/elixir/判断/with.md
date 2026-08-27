# with

## 说明

链式匹配，所以待匹配变量无需定义

如果某个 step 失败，之前的还是会成功执行

## 用法

```elixir
defmodule WithDemo do
  require Logger

  def demo do
    with {:ok, result1} <- step1(),
         {:ok, result2} <- step2(result1),
         {:ok, result3} <- step3(result2) do
      Logger.debug("final result #{result1 + result2 + result3}")
    else
      {:failed, reason} ->
        Logger.debug("step2 失败: #{inspect(reason)}")

      _ ->
        Logger.debug("其他未匹配的错误")
    end
  end

  def step1() do
    Logger.debug("in step1")
    {:ok, 111}
  end

  def step2(arg) do
    Logger.debug("in step2 #{inspect(arg)}")

    if arg > 200 do
      {:ok, 222}
    else
      {:failed, 222}
    end
  end

  def step3(arg) do
    Logger.debug("in step3 #{arg}")

    if arg > 200 do
      {:ok, 333}
    else
      {:timeout, 333}
    end
  end
end
```
