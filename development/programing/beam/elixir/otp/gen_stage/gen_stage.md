# gen_stage

elixir 基于 gen_server 实现的生产者/消费者模型

## 说明

生产者的 handle_demand 被消费者调用取决于 max_demand - min_demand 的结果

## 例子

a.ex

```elixir
defmodule A do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(state) do
    {:producer, state}
  end


  def handle_demand(demand, state) when demand > 0 do
    events = ["111", "222", "333"]
    # IO.puts("#{events} in A")
    {:noreply, events, state}
  end
end
```

b.ex

```elixir
defmodule B do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(state) do
    {
      :producer_consumer,
      state,
      subscribe_to: [{A, max_demand: 1}]
    }
  end

  def handle_events(events, _from, state) do
    # IO.puts("#{events} in B")
    {:noreply, events, state}
  end
end
```

c.ex

```elixir
defmodule C do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {
      :consumer,
      :the_state_does_not_matter,
      subscribe_to: [{B, max_demand: 1}]
    }
  end

  def handle_events(events, _from, state) do
    Process.sleep(1000)
    IO.puts("#{events} #{inspect(self())}")
    {:noreply, [], state}
  end
end
```

demo.ex

```elixir
defmodule Demo do
  def hello do
    GenStage.start_link(A, 0, name: A)
    GenStage.start_link(B, 2, name: B)

    GenStage.start_link(C, :ok)
    GenStage.start_link(C, :ok)
    GenStage.start_link(C, :ok)
    GenStage.start_link(C, :ok)
    GenStage.start_link(C, :ok)
  end
end
```
