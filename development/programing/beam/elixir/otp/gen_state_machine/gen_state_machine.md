# gen_state_machine

## 说明

[封装过的三方库](https://github.com/ericentin/gen_state_machine)

## 代码

mix.exs

```elixir
defp deps do
  [
    {:gen_state_machine, "~> 3.0"}
  ]
end
```

```elixir
defmodule Switcher do
  use GenStateMachine
  require Logger

  def start_link() do
    GenStateMachine.start_link(__MODULE__, {:off, 0})
  end

  # off 的状态，返回 on
  def handle_event(:cast, :flip, :off, data) do
    Logger.debug("event: :off, data #{inspect(data)}")
    {:next_state, :on, data + 1}
  end

  # on 的状态
  def handle_event(:cast, :flip, :on, data) do
    Logger.debug("event: :on, data #{inspect(data)}")
    {:next_state, :off, data}
  end

  # get_count 事件
  def handle_event({:call, from}, :get_count, state, data) do
    Logger.debug("event: :get_count, state #{inspect(state)} data #{inspect(data)}")
    {:next_state, state, data, [{:reply, from, data}]}
  end

  # 其它事件
  def handle_event(event_type, event_content, state, data) do
    Logger.debug("default handle_event")
    super(event_type, event_content, state, data)
  end
end
```

```elixir
defmodule Demo do
  def demo do
    {:ok, pid} = Switcher.start_link()
    GenStateMachine.cast(pid, :flip)
    GenStateMachine.call(pid, :get_count)
  end
end
```
