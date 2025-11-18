# plug

## 说明

类似其他语言里面的 middleware

## 种类

### 方法级

访问 index 页面的时候，会触发 plug

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller
  require Logger

  plug :aaa
  plug :bbb
  plug :ccc

  def index(conn, _params) do
    render(conn, "index.html")
  end

  defp aaa(conn, _opts) do
    Logger.debug("aaa")
    conn
  end

  defp bbb(conn, _opts) do
    Logger.debug("bbb")
    conn
  end

  defp ccc(conn, _opts) do
    Logger.debug("ccc")
    conn
  end
end
```

### 模块级

```elixir
defmodule WebDemoWeb.Plugs.Locale do
  import Plug.Conn
  require Logger

  def init(default_locale) do
    # 返回值是 call 的第二个参数
    default_locale
  end

  # 必须返回 conn
  def call(conn, default_locale) do
    # 前置
    conn |> assign(:demo_locale, default_locale)

    # 后置
    conn |> register_before_send(&__MODULE__.on_post_call/1)
  end

  # 必须返回 conn， 或者 halt() 不让 controller 处理请求
  def on_post_call(conn) do
    Logger.debug("on_post_call")

    err_map =
      Map.new()
      |> Map.put("data", :null)
      |> Map.put("message", "token 验证失败")
      |> Map.put("status", 502)

    conn
    |> put_status(502)
    |> put_resp_content_type("application/json")
    |> send_resp(502, Jason.encode!(err_map))
    |> halt()
  end
end
```

注册，这里添加到 router 里面

```elixir
pipeline :browser do
  # 必须放在 pipeline 里面
  plug WebDemoWeb.Plugs.Locale, "xxxxxxx"
end
```

页面里面获取自定义变量

```html
<p>Locale: <%= @demo_locale %></p>
```

controller 里面获取自定义变量

```elixir
conn.assigns.demo_locale
```

## 注册位置

### router 注册

把 Plug 放在 Pipeline 里面， Pipeline 是一系列 Plug 的组合，执行顺序为**从上到下**

```elixir
pipeline :browser do
  plug :aaa
  plug :bbb
  plug WebDemoWeb.Plugs.Locale, "en"
end

scope "/", WebDemoWeb do
  pipe_through :browser

end
```

### controller 注册

一般在 controller 里面注册，用于响应某些 action

```elixir
defmodule WebDemoWeb.HelloController do
  use WebDemoWeb, :controller

  plug WebDemoWeb.Plugs.Locale, "zzz" when action in [:index]
```

### 在 endpoint 注册

为全局效果

```elixir
def introspect(conn, _opts) do
  Logger.debug("""
  Verb: #{inspect(conn.method)}
  Host: #{inspect(conn.host)}
  Headers: #{inspect(conn.req_headers)}
  """)

  conn
end


# 所有的请求都会打印出来
plug :introspect
plug WebDemoWeb.Router
```
