# plug

## 说明

类似其他语言里面的 middleware

## 例子

### 控制器方法

不同的控制器，需要以不同的逻辑处理

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller
  require Logger

  # 注意写法
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

### 独立模块

统一处理的逻辑

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

```html
<!-- 页面里面获取 -->
<p>Locale: <%= @demo_locale %></p>
```

```elixir
# plug 里面获取
conn.assigns.demo_locale
```

### 全局

endpoint.ex

```elixir
defmodule WebdemoWeb.Endpoint do
  ......

  # 定义
  def introspect(conn, _opts) do
    Logger.debug("""
    Verb: #{inspect(conn.method)}
    Host: #{inspect(conn.host)}
    Headers: #{inspect(conn.req_headers)}
    """)

    conn
  end

  ......

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  # 这里注册
  plug :introspect
  plug WebdemoWeb.Router
end
```
