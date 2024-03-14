# plug

就是其他语言的 web 框架里面的 middleware

[参考文档](https://hexdocs.pm/plug/readme.html)

## 说明

执行顺序

```sh
plug 的 init
plug 的 call
controller 的 action
```

## 种类

### 方法级 plug

conn 为 %Plug.Conn{}

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :aaa
  plug :bbb
  plug :ccc

  def index(conn, _params) do
    render(conn, "index.html")
  end

  defp aaa(conn, _opts) do
    IO.puts("aaa")
    conn
  end

  defp bbb(conn, _opts) do
    IO.puts("bbb")
    conn
  end

  defp ccc(conn, _opts) do
    IO.puts("ccc")
    conn
  end
end
```

### 模块级 plug

init 的返回值会 call 方法的第二个参数, call 必须返回 conn 对象

```elixir
defmodule HelloWeb.Plugs.Locale do
  def init(default_locale) do
    default_locale
  end

  def call(conn, default_locale) do
    # 前置
    conn |> Plug.Conn.assign(:locale, default_locale)

    # 后置
    conn |> Plug.Conn.register_before_send(&__MODULE__.on_post_call/1)
  end

  def on_post_call(conn) do
    IO.puts("on_post_call")
    # 这里必须返回 conn
    conn
  end
end
```

注册，这里添加到 router 里面

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    ...........

    plug HelloWeb.Plugs.Locale, "xxxxxxx"
  end
```

页面里面，加这个

```html
<p>Locale: <%= @locale %></p>
```

## 注册位置

### endpoint 里面注册

路径在 `lib/web_demo_web/endpoint.ex` 里面

### router 注册

router 里面注册的时候，我们可以把 Plug 放在 Pipeline 里面， Pipeline 是一系列 Plug 的组合，执行顺序为**从上到下**

```elixir
defmodule HelloWeb.Router do
  use HelloWeb, :router

  pipeline :browser do
    plug :aaa
    plug :bbb
    plug :ccc
    plug :aaa
    plug HelloWeb.Plugs.Locale, "en"
  end

  scope "/", HelloWeb do
    pipe_through :browser

  end
```

### controller 注册

一般在 controller 里面注册，用于响应某些 action

```elixir
defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  plug HelloWeb.Plugs.Locale, "zzz" when action in [:index]
```
