# broadway

## 说明

broadway 自己启动注册的 producer, 在消息的回调里面处理消息

和 gen stage 不一样

```sh
Producer → ProducerConsumer1 → ProducerConsumer2 → Consumer
```

以上这种，不支持

## 例子

```elixir
defmodule Producer do
  use GenStage

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    events = Enum.to_list(counter..(counter + demand - 1))

    # 包装为 broadway 的消息
    messages =
      Enum.map(events, fn event ->
        %Broadway.Message{
          data: event,
          acknowledger: Broadway.NoopAcknowledger.init()
        }
      end)

    {:noreply, messages, counter + demand}
  end
end
```

```elixir
defmodule Pipeline do
  use Broadway
  require Logger

  def start() do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Producer, 0},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 4,
          max_demand: 22,
          min_demand: 11
        ]
      ]
    )
  end

  def handle_message(_processor, message, _context) do
    Logger.debug("处理事件 #{inspect(message.data)}")
    message
  end
end
```

```elixir
defmodule Demo do
  def demo() do
    Pipeline.start()
  end
end
```
