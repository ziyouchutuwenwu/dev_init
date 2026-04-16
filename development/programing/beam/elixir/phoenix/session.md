# session

## 说明

session 依赖于本地 cookie，请求带着的 cookie 不同，结果也不同

## 例子

### 注册

在 router 里面注册

```elixir
pipeline :api do
  plug :fetch_session
  plug :accepts, ["json"]
end
```

或者手动获取

```elixir
conn = fetch_session(conn)
```

### 读写

```elixir
conn |> get_session(user_id)
```

```elixir
conn = conn |> put_session(user_id, token)
```

```elixir
conn = conn |> delete_session(user_id)
```
