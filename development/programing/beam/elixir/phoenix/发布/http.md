# http

## 说明

嵌入式里面，ssl 往往没有，此时，用 http 启动

## 用法

prod.exs

注释掉

```elixir
# 前面是 nginx 的 https, 后面跑 phoenix 的 http
config :web_demo, WebDemoWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      # paths: ["/health"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]
```

runtime.exs

```elixir
if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT", "4000"))

  config :web_demo, WebDemoWeb.Endpoint,
    # 为 phoenix 的 url 辅助函数（如 ~p、url/3） 生成连接
    url: [host: host, port: port, scheme: "http"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :web_demo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
end
```
