# json

## 例子

### 创建项目

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

### 路由

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :api

  post "/log", LogController, :log
end
```

### controller

page_controller.ex

```elixir
defmodule WebDemoWeb.LogController do
  use WebDemoWeb, :controller

  def log(conn, log_map) do
    conn
    # |> put_status(:ok)
    |> json(%{status: "success", log: log_map})
  end
end
```
