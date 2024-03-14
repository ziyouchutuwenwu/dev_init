# cors

## 步骤

### 添加依赖

```elixir
def deps do
  # ...
  {:cors_plug, "~> 3.0"},
  #...
end
```

### 注册

- endpoint 里面注册

```elixir
defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  # ...
  plug CORSPlug

  plug YourApp.Router
end
```

- pipeline 里注册

```elixir
pipeline :api do
  plug CORSPlug
  # ...
end

scope "/api", PhoenixApp do
  pipe_through :api

  resources "/articles", ArticleController
  options   "/articles", ArticleController, :options
  options   "/articles/:id", ArticleController, :options
end
```
