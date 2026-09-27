# gen_stage

## 说明

otp 原生没有，elixir 里面增加的

consumer来拉数据，不是 producer 推过去的

## 例子

```elixir
defmodule Producer do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, 0}
  end

  # consumer 的库存为 min_demand 的时候，就会触发
  # demand 为 max_demand - min_demand
  # 第一次为 max_demand
  def handle_demand(demand, counter) when demand > 0 do
    events = Enum.to_list(counter..(counter + demand - 1))
    {:noreply, events, counter + demand}
  end
end
```

```elixir
defmodule Consumer do
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:consumer, :ok}
  end

  def handle_events(events, _from, state) do
    Process.sleep(100)
    Logger.debug("处理事件 #{inspect(events)}")
    {:noreply, [], state}
  end
end
```

```elixir
defmodule Demo do
  def demo do
    Producer.start_link()
    Consumer.start_link()

    GenStage.sync_subscribe(
      Consumer,
      to: Producer,
      max_demand: 22,
      min_demand: 11
    )
  end
end
```
