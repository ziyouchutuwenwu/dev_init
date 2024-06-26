# csrf

## 说明

防止跨站伪造的请求, 对于 POST, PUT, DELETE 请求生效

### 请求字段

任选一

| 位置                  | 字段         |
| --------------------- | ------------ |
| header                | x-csrf-token |
| form-data             | \_csrf_token |
| x-www-form-urlencoded | \_csrf_token |

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

### 纯接口

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  # 独立出来
  pipeline :csrf do
    # fetch_session 不能忽略
    plug :fetch_session
    plug :protect_from_forgery

    # 用于防止 xss, 这里可以不用
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WebDemoWeb do
    # pipe_through [:api, :csrf]

    pipe_through :api
    pipe_through :csrf

    get "/get", DemoController, :get
    get "/delete", DemoController, :delete
    post "/check", DemoController, :check
  end
end
```

demo_controller.ex

```elixir
defmodule WebDemoWeb.DemoController do
  use WebDemoWeb, :controller

  def get(conn, _assigns) do
    json(conn, %{token: get_csrf_token()})
  end

  def delete(conn, _assigns) do
    json(conn, %{token: delete_csrf_token()})
  end

  # 非 get 请求, 需要另外加字段, 否则返回 403
  def check(conn, _assigns) do
    json(conn, %{message: "check"})
  end
end
```

### 测试

```sh
mix phx.server
```
