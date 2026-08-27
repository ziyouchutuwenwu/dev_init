# libcluster

## 说明

发现支持 epmd, gossip, k8s 等策略

多种策略可以同时配置

连接用 erlang 自己的，也就是原来 erlang 的节点监控之类的都可以用

## 代码

```elixir
{:libcluster, "~> 3.5"}
```

```elixir
defmodule Demo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      gossip: [
        strategy: Cluster.Strategy.Gossip
      ],
      epmd: [
        strategy: Cluster.Strategy.Epmd
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Demo.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

测试

```sh
iex --name xx@127.0.0.1 --cookie 123456 -S mix

# 不需要主动连接，他会自动连接
iex --name a@127.0.0.1 --cookie 123456 -S mix
```
