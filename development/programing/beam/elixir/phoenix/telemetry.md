# telemetry

类似一个事件记录器，直接看代码

## 例子

代码

```elixir
defmodule TelemetryDemo do
  require Logger

  def setup do
    events = [
      [:aaa, :bbb, :ccc]
    ]

    :telemetry.attach_many("my-name", events, &__MODULE__.on_event/4, nil)
  end

  def on_event([:aaa, :bbb, :ccc], measurements, metadata, _config) do
    Logger.info("on_event: [#{measurements.xxx} total for #{metadata.yyy}]")
  end

  def fire(product, quantity, amount) do
    total = quantity * amount

    :telemetry.execute(
      [:aaa, :bbb, :ccc],
      %{xxx: total},
      %{yyy: product}
    )

    "Sold #{product}: #{quantity} units at #{amount} each. Total #{total}"
  end
end
```
