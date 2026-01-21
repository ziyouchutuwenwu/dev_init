# cors

## 说明

允许来自其它域名的访问

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

### 添加依赖

```elixir
def deps do
  # ...
  {:cors_plug, "~> 3.0"},
  #...
end
```

### 注册方式

endpoint 内注册优先于路由

#### endpoint

lib/web_demo_web/endpoint.ex

```elixir
plug CORSPlug
plug WebDemoWeb.Router
```

#### router

lib/web_demo_web/router.ex

```elixir
pipeline :api do
  plug CORSPlug
  plug :accepts, ["json"]
end
```
