# umbrella

## 步骤

### 创建项目

```sh
mix new umbrella_demo --umbrella
cd umbrella_demo/apps
mix new demo
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

### 配置文件

最外层的 config.exs

```elixir
import Config

for config <- "../apps/*/config/config.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  import_config config
end
```

### 子项目

需要自动启动的 application, 在子应用的 mix.exs 里面配置
