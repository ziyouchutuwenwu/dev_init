# nerveshub

## 分类

[nerves_hub_web](https://github.com/nerves-hub/nerves_hub_web) 是服务端平台

固件部分

### nerves_hub_web

```sh
rm -rf .tool-versions
```

启动必需的 docker 服务

```sh
# docker-compose.yml
docker compose up -d
```

编译

```sh
mix deps.get
mix compile
mix assets.install
mix ecto.reset
```

启动

```sh
iex -S mix phx.server
```

默认账号密码

```sh
nerveshub@nerves-hub.org
nerveshubweb
```

用户

```sh
用户必须处于某个 team 里面
personal 里面，只能是当前登录用户，无法管理 users
```

创建共享 secret

```sh
team
  -> xx 产品
    settigs
      -> Device Shared Secret Authentication
```

### 固件

公钥写入固件 config.exs

```elixir
# deps
{:nerves_hub_link, "~> 2.2"},
```

config.exs

```elixir
config :nerves_hub_link,
  configurator: NervesHubLink.Configurator.SharedSecret,
  ssl_configurator: NervesHubLink.Configurator.SharedSecret,
  host: "ws://10.0.2.1:4000",
  remote_iex: true,
  # identifier: "dev_device_001",
  shared_secret: [
    product_key: "xxxxxxxxxxx",
    product_secret: "xxxxxxxxxxx"
  ],
  ssl: [verify: :verify_none]
```

编译

```sh
mix firmware
```

上传

网页里面的产品名字，要和 nerves 的 mix.exs 里 app 名字一致

```sh
nh config set product nerves_demo
# 发布需要私钥
nh firmware publish --key my_key
```
