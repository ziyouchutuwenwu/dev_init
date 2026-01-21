# nebulex

## 说明

缓存，可以和 libcluster 配合

## 代码

```elixir
{:libcluster, "~> 3.5"},
{:nebulex, "~> 3.0.0-rc.1"},
{:nebulex_distributed, "~> 3.0.0-rc.1"},
```

```elixir
defmodule Demo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Cache
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
defmodule Cache do
  use Nebulex.Cache,
    otp_app: :demo,
  adapter: Nebulex.Adapters.Partitioned
end
```

```elixir
defmodule Demo do
  def set do
    Cache.put("xxx", "123456")
  end

  def get do
    Cache.get("xxx")
  end
end
```
