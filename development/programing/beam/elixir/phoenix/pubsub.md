# pubsub

## 例子

```elixir
defmodule Demo do
  def start_pubsub() do
    children = [
      {Phoenix.PubSub, name: :demo_pubsub},
    ]

    opts = [strategy: :one_for_one, name: :demo_pubsub_sup]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
Demo.start_pubsub()

alias Phoenix.PubSub
PubSub.subscribe :demo_pubsub, "user:123"
Process.info(self(), :messages)
PubSub.broadcast :demo_pubsub, "user:123", {:user_update, %{id: 123, name: "Shane"}}
Process.info(self(), :messages)
```
