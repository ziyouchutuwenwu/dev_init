# 自定义 layout

## 例子

aaa_controller.ex

```elixir
defmodule WebDemoWeb.AaaController do
  use WebDemoWeb, :controller

  def aaa(conn, _params) do

    # ppp.html.heex
    conn
    |> put_layout(html: :ppp)
    |> render(:mmm)
  end
end
```
