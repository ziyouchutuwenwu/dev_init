# csrf

## 说明

页面模式默认开启，以下只描述纯 api 的模式

## 例子

### 纯接口

非 get 传参的时候，要加名为 x-csrf-token 的头，否则自动抛出 403 错误

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  # 独立出来
  pipeline :csrf do
    # fetch_session 不能忽略
    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WebDemoWeb do
    pipe_through [:api, :csrf]

    get "/get1", PageController, :get1
    post "/post1", PageController, :post1
    post "/post2", PageController, :post2
  end
end
```

page_controller.ex

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def get1(conn, _assigns) do
    json(conn, %{token: get_csrf_token()})
  end

  def post1(conn, _assigns) do
    json(conn, %{message: "post1"})
  end

  def post2(conn, _assigns) do
    json(conn, %{message: "post2"})
  end
end
```
