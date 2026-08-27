# fallback

## 准备

准备好自定义错误页

## 例子

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  action_fallback WebDemoWeb.FallbackController

  def home(conn, _params) do
    render(conn, :home)
  end

  def demo(_conn, _params) do
     {:error, :not_found}
    # {:error, :unauthorized}
  end
end
```

```elixir
defmodule WebDemoWeb.FallbackController do
  use WebDemoWeb, :controller
  require Logger

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: WebDemoWeb.ErrorHTML, json: WebDemoWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(403)
    |> put_view(html: WebDemoWeb.ErrorHTML, json: WebDemoWeb.ErrorJSON)
    |> render(:"403")
  end
end
```
