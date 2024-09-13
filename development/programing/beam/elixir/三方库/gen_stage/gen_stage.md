# gen_stage

## 说明

生产者/消费者模型，三方库，非 otp 实现

## 例子

### 场景说明

A 为生产者
B 既是消费者，又是生产者
C 为消费者

```sh
[A] -> [B] -> [C]
```

A 生产出来，经过 B 的部分消费，再经过 C 的消费以后，再继续走到 A，类似拉的模式

### 代码

a.ex

```elixir
defmodule A do
  use GenStage
  require Logger

  def start_link(state) do
    # B 订阅事件需要 A 的 name
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    Logger.debug("init state #{inspect(state)} #{inspect(__MODULE__)}")
    {:producer, state}
  end

  def gen_list(n) do
    1..n
    |> Enum.map(fn i -> Integer.to_string(i) <> Integer.to_string(i) <> Integer.to_string(i) end)
  end

  # 在被消费的时候，会触发这里
  def handle_demand(demand, state) when demand > 0 do
    # Process.sleep(1000)

    list = gen_list(9)
    events = list

    Logger.debug(
      "A demand #{inspect(demand)}, state #{inspect(state)}, events #{inspect(events)}"
    )

    {:noreply, events, state}
  end
end
```

b.ex

```elixir
defmodule B do
  use GenStage
  require Logger

  def start_link(state) do
    # C 订阅事件需要 B 的 name
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
    # GenStage.start_link(__MODULE__, :ok)
  end

  def init(state) do
    Logger.debug("init in #{inspect(__MODULE__)}")

    {
      :producer_consumer,
      state,
      subscribe_to: [
        {
          A,
          # 当消费者处理完当前的事件后，它会向生产者请求更多事件，直到达到设置的 max_demand 为止。这可以有效地控制从生产者到消费者的流量
          # 通过设置一个最低需求，消费者可以减少发送请求的频率，从而提高效率，尤其是在事件的产生速度比较快的情况下。
          max_demand: 10, min_demand: 5
        }
      ]
    }
  end

  def handle_events(events, _from, state) do
    Process.sleep(3000)
    Logger.debug("B state #{inspect(state)}, events #{inspect(events)}")
    {:noreply, events, state}
  end
end
```

c.ex

```elixir
defmodule C do
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.debug("init in #{inspect(__MODULE__)}")

    {
      :consumer,
      :the_state_does_not_matter,
      subscribe_to: [
        {
          B,
          max_demand: 1
        }
      ]
    }
  end

  def handle_events(events, _from, state) do
    Process.sleep(1000)
    Logger.debug("C state #{inspect(state)}, events #{inspect(events)}")
    {:noreply, [], state}
  end
end
```

demo_sup.ex

```elixir
defmodule DemoSup do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_arg) do
    Logger.debug("init in #{inspect(__MODULE__)}")

    children = [
      %{
        id: A,
        start: {A, :start_link, [0]}
      },
      %{
        id: B,
        start: {B, :start_link, [3]}
      },
      %{
        id: :c1,
        start: {C, :start_link, []}
      },
      %{
        id: :c2,
        start: {C, :start_link, []}
      }
    ]

    # 注意这里的策略
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
```

demo.ex

```elixir
defmodule Demo do

  def demo do
    A.start_link(0)
    B.start_link(3)
    C.start_link()
    # C.start_link()
  end

  def demo1 do
    DemoSup.start_link()
  end
end
```
