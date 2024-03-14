# pipe_through

将多个 pipeline 进行组合，执行顺序为**从上到下**

## 例子

```elixir
defmodule DemoPlug1 do
  import Plug.Conn

  def init(default) do
    default
  end

  def call(conn, default_locale) do
    IO.puts("in plug1")
    conn = assign(conn, :locale, default_locale)
    conn
  end
end
```

```elixir
defmodule DemoPlug2 do
  import Plug.Conn

  def init(default) do
    default
  end

  def call(conn, default_locale) do
    IO.puts("in plug2")
    conn = assign(conn, :locale, default_locale)
    conn
  end
end
```

```elixir
defmodule DemoPlug3 do
  import Plug.Conn

  def init(default) do
    default
  end

  def call(conn, default_locale) do
    IO.puts("in plug3")
    conn = assign(conn, :locale, default_locale)
    conn
  end
end
```

router.ex

```elixir
pipeline :ccc do
  plug DemoPlug3
end

pipeline :bbb do
  plug DemoPlug2
end

pipeline :aaa do
  plug DemoPlug1
end

scope "/", DemoWeb do
  pipe_through :browser
  pipe_through [:ccc, :bbb]
  pipe_through :aaa

  get "/", PageController, :index
end
```
