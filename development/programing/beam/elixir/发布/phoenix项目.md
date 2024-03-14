# phoenix 项目

[参考地址](https://hexdocs.pm/phoenix/deployment.html)

## 步骤

### 修改配置

#### config/prod.exs

动态端口配置可以参考 config/runtime.exs

```elixir
config :xxx, XxxWeb.Endpoint,
  # url: [host: "example.com", port: 80],
  http: [ip: {0,0,0,0}, port: 4200],
  cache_static_manifest: "priv/static/cache_manifest.json",
  # 在系统启动的时候，运行 Cowboy 应用的 http 服务
  server: true,
  # 放置并提供静态文件的路径
  root: ".",
  # 当系统版本升级的时候，系统缓存就会被清除
  version: Application.spec(:book_app, :vsn)
```

### 编译

```sh
mix deps.get --only prod
MIX_ENV=prod mix compile

MIX_ENV=prod mix assets.deploy
# MIX_ENV=prod mix ecto.migrate
MIX_ENV=prod mix release
export SECRET_KEY_BASE=`mix phx.gen.secret` PHX_SERVER=true PHX_HOST="aaa.com" PORT=9876;
_build/prod/rel/web_demo/bin/web_demo start
```

### 注意

如果 tailwind 无法下载，则修改

```sh
deps/tailwind/lib/tailwind.ex的 default_base_url
```

改完以后，需要重新编译

### 其它

参考 [普通项目发布](./%E6%99%AE%E9%80%9A%E9%A1%B9%E7%9B%AE%E5%8F%91%E5%B8%83.md)
