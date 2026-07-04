# http 模式

## 说明

嵌入式里面，ssl 往往没有，此时，用 http 启动

## 用法

prod.exs

以下去掉

```elixir
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
# 用浏览器访问，用哪个域名填哪个域名，用 ip 填 ip
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
```
