# json 基础

## 例子

```elixir
defmodule WebDemoWeb.DemoController do
  use WebDemoWeb, :controller

  def get_demo(conn, params) do
    json(conn, %{params: params})
  end
end
```
