# layout

## 说明

```sh
# 内置
components/layouts.ex
theme_toggle 切换主题
app 是顶部导航栏，内部带切换主题
```

## 用法

引用内置 layout

```elixir
<Layouts.app flash={@flash}>
  爱上大三大四的
</Layouts.app>
```

自定义 layout

```sh
components/layouts/xxx.html.heex
```

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: {WebDemoWeb.Layouts, :xxx})
  end
end
```

或者

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  plug :put_layout, html: {WebDemoWeb.Layouts, :xxx}

  def home(conn, _params) do
    render(conn, :home)
  end
end
```
