# title

## 说明

动态 title 和 description 的例子

## 例子

heex

```html
<.live_title default="WebDemo" suffix="">
  {assigns[:page_title]}
</.live_title>
<meta name="description" content={assigns[:page_description] || "aaaaaaa"} />
```

controller

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :seo_plug

  def home(conn, _params) do
    render(conn, :home)
  end

  defp seo_plug(conn, _opts) do
    conn
    |> assign(:page_title, "aaaaaaaaaaaaaaaaaaa")
    |> assign(:page_description, "bbbbbbbbbbbbbbbbbbbb")
  end
end
```
