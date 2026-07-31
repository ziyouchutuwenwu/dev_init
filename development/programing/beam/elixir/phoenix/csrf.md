# csrf

## 说明

防止跨站伪造的请求, 对于 POST, PUT, DELETE 请求生效

服务端全自动处理，客户端表单提交的时候带上 `_csrf_token` 这个隐藏字段

## 例子

```sh
mix phx.new web_demo --no-assets --no-html --no-gettext --no-dashboard --no-live --no-mailer --no-ecto
```

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home
  post "/users", PageController, :create_user
end
```

home.html.heex

```html
<div class="p-6 max-w-lg mx-auto space-y-8">

  <div class="p-4 border rounded-xl shadow-xs bg-base-100">
    <h2 class="text-lg font-bold mb-4">表单 1：组件形式（自动带 CSRF Token）</h2>
    <.form :let={f} for={@form} action={~p"/users"}>
      <.input field={f[:name]} type="text" label="Name" />
      <button type="submit" class="btn btn-primary mt-2">自动Token提交</button>
    </.form>
  </div>

  <div class="p-4 border rounded-xl shadow-xs bg-base-100">
    <h2 class="text-lg font-bold mb-4">表单 2：原生 HTML（手动带 CSRF Token）</h2>
    <form action="/users" method="post" class="space-y-4">
      <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
      <div>
        <label class="label"><span class="label-text">Name</span></label>
        <input type="text" name="user[name]" value={@form.source["name"]} class="input input-bordered w-full" />
      </div>
      <button type="submit" class="btn btn-secondary">手动Token提交</button>
    </form>
  </div>

</div>
```

page_controller.ex

```elixir
defmodule WebDemoWeb.PageController do
  use WebDemoWeb, :controller

  def home(conn, _params) do
    form = Phoenix.Component.to_form(%{"name" => ""}, as: :user)
    render(conn, :home, form: form)
  end

  def create_user(conn, %{"user" => user_params}) do
    IO.inspect(user_params, label: "====== RECEIVED =====")

    conn
    |> put_flash(:info, "用户 #{user_params["name"]} 创建成功")
    |> redirect(to: ~p"/")
  end
end
```
