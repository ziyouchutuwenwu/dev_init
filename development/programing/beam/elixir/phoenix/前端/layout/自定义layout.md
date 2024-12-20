# 自定义 layout

## 说明

| 文件                   | 说明                               |
| ---------------------- | ---------------------------------- |
| layouts/root.html.heex | 项目最底层的模板                   |
| layouts/app.html.heex  | root 模板 inner_content 包含的模板 |

## 例子

lib/web_demo_web/controllers/aaa_controller.ex

```elixir
defmodule WebDemoWeb.AaaController do
  use WebDemoWeb, :controller

  def aaa(conn, _params) do

    # lib/web_demo_web/components/layouts/ppp.html.heex
    conn
    |> put_layout(html: :ppp)
    |> render(:mmm)
  end
end
```
