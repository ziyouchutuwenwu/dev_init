# token 验证

## 方法

```elixir
user_id = 88
token = Phoenix.Token.sign(WebDemoWeb.Endpoint, "user auth", user_id)
Phoenix.Token.verify(WebDemoWeb.Endpoint, "user auth", token, max_age: 86400)
```

```elixir
user_id    = 99
secret     = "kjoy3o1zeidquwy1398juxzldjlksahdk3"
namespace  = "user auth"
token      = Phoenix.Token.sign(secret, namespace, user_id)
Phoenix.Token.verify(secret, namespace, token, max_age: 8)
```
