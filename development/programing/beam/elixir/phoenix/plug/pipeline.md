# pipeline

## 说明

Pipeline 是一系列 Plug 的组合，执行顺序为**从上到下**

pipeline 也可以作为 plug

## 例子

```elixir
defmodule DemoPlug1 do
  import Plug.Conn
  require Logger

  def init(arg) do
    arg
  end

  def call(conn, arg) do
    Logger.debug("in plug1")
    conn |> assign(:plug1, arg)
  end
end
```

```elixir
defmodule DemoPlug2 do
  import Plug.Conn
  require Logger

  def init(arg) do
    arg
  end

  def call(conn, arg) do
    Logger.debug("in plug2")
    conn |> assign(:plug2, arg)
  end
end
```

```elixir
defmodule DemoPlug3 do
  import Plug.Conn
  require Logger

  def init(arg) do
    arg
  end

  def call(conn, arg) do
    Logger.debug("in plug3")
    conn |> assign(:plug3, arg)
  end
end
```

```elixir
defmodule DemoPlug4 do
  import Plug.Conn
  require Logger

  def init(arg) do
    arg
  end

  def call(conn, arg) do
    Logger.debug("in plug4")
    conn |> assign(:plug4, arg)
  end
end
```

router.ex

```elixir
pipeline :aaa do
  plug DemoPlug1
end

pipeline :bbb do
  # pipeline 可以作为 plug
  plug :aaa
  plug DemoPlug2
end

pipeline :ccc do
  plug DemoPlug3
end

pipeline :ddd do
  plug DemoPlug4
end

scope "/", DemoWeb do
  pipe_through :browser
  pipe_through [:ccc, :bbb]
  pipe_through :ddd

  get "/", PageController, :index
end
```
