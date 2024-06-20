# agent

agent 是基于 gen_server 实现的用于存储数据的进程

## 用法

```elixir
defmodule Bucket do
  use Agent

  def start_link() do
    Agent.start_link(fn -> _init() end, name: __MODULE__)
  end

  def put(key, value) do
    Agent.update(__MODULE__, fn state -> _put(state, key, value) end)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state -> _get(state, key) end)
  end

  # ----------------------------------------------------------------------
  defp _init() do
    Map.new()
  end

  defp _get(state, key) do
    Map.get(state, key)
  end

  defp _put(state, key, value) do
    Map.put(state, key, value)
  end
end
```
