# gen_stage

## 说明

生产者/消费者模型，三方库，非 otp 实现

## 例子

```elixir
defmodule Producer do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, 0}
  end

  # 根据需求(demand)生成事件
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

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # 订阅生产者，最大需求为5
    {:consumer, :ok, subscribe_to: [{Producer, max_demand: 5}]}
  end

  def handle_events(events, _from, state) do
    Process.sleep(1000)
    Logger.debug("处理事件 #{inspect(events)}")
    {:noreply, [], state}
  end
end
```

```elixir
defmodule Demo do
  def demo do
    Producer.start_link([])
    Consumer.start_link([])
  end
end
```
