# gen_state_machine

[地址](https://github.com/ericentin/gen_state_machine)

## 代码如下

创建项目

```sh
mix new demo
```

```elixir
defmodule Switch do
  use GenStateMachine

  def start_link() do
    GenStateMachine.start_link(Switch, {:off, 0})
  end

  def flip(pid) do
    GenStateMachine.cast(pid, :flip)
  end

  def get_count(pid) do
    GenStateMachine.call(pid, :get_count)
  end

  @impl true
  def handle_event(:cast, :flip, :off, data) do
    {:next_state, :on, data + 1}
  end

  @impl true
  def handle_event(:cast, :flip, :on, data) do
    {:next_state, :off, data}
  end

  @impl true
  def handle_event({:call, from}, :get_count, state, data) do
    {:next_state, state, data, [{:reply, from, data}]}
  end

  @impl true
  def handle_event(event_type, event_content, state, data) do
    # Call the default implementation from GenStateMachine
    super(event_type, event_content, state, data)
  end
end
```

修改

mix.exs

```elixir
def application do
  [
    extra_applications: [:gen_state_machine, :logger]
  ]
end

defp deps do
  [
    {:gen_state_machine, "~> 3.0"}
  ]
end
```

## 测试

```elixir
{:ok, pid} = Switch.start_link()
GenStateMachine.cast(pid, :flip)
GenStateMachine.call(pid, :get_count)
```
