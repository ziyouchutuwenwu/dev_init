# logger

## 用法

config.exs

```elixir
config :logger,
  level: :info,
  backends: [:console]
```

```elixir
require Logger

Logger.info("测试")
```
