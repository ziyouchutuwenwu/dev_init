# json_html 共享路由

## 说明

在一个路由内，同时支持 hmtl 和 json

## 例子

router.ex

```elixir
pipeline :browser do
  plug :accepts, ["html", "json"]
end

scope "/", HelloWeb do
  pipe_through :browser

  get "/", PageController, :index
end
```

lib/hello_web/controllers/page_controller.ex

```elixir
defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  plug :put_view, html: HelloWeb.PageHTML, json: HelloWeb.PageJSON

  def index(conn, _params) do
    render(conn, :index, layout: false)
  end
end
```

lib/hello_web/controllers/page_json.ex

```elixir
defmodule HelloWeb.PageJSON do
  def index(_assigns) do
    %{message: "this is some JSON"}
  end
end
```

测试

```sh
http://localhost:4000/?_format=json
```
