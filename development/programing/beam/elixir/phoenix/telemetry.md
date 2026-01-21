# telemetry

类似一个事件记录器，直接看代码

## 例子

代码

```elixir
defmodule Demo do
  require Logger

  def init do
    single_event = [:event9]
    :telemetry.attach("demo_single", single_event, &__MODULE__.on_event/4, nil)

    multi_events = [
      [:event1],
      [:event2]
    ]
    :telemetry.attach_many("demo_multi", multi_events, &__MODULE__.on_multi_event/4, nil)
  end

  def on_event(event, measurements, metadata, _config) do
    Logger.info(
      "on_single: event #{inspect(event)} measurements #{inspect(measurements)} metadata #{inspect(metadata)}"
    )
  end

  def on_multi_event(events, measurements, metadata, _config) do
    Logger.info(
      "on_multi: event #{inspect(events)} measurements #{inspect(measurements)} metadata #{inspect(metadata)}"
    )
  end

  def demo do
    :telemetry.execute(
      [:event9],
      %{xxx: "x9"},
      %{yyy: "y9"}
    )

    :telemetry.execute(
      [:event1],
      %{xxx: "x1"},
      %{yyy: "y1"}
    )

    :telemetry.execute(
      [:event2],
      %{xxx: "x2"},
      %{yyy: "y2"}
    )
  end
end
```
