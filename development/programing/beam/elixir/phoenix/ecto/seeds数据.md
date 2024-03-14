# seeds 数据

用于一个命令创建预定义数据

## 步骤

vim priv/repo/seeds.exs

```elixir
alias Demo.{Repo, User, Avatar}

avatar = %Avatar{nick_name: "avatar1", pic_url: "http://elixir-lang.org/images/logo.png"}
user = %User{name: "user1", email: "user1@example.com", avatar: avatar}
user = Repo.insert!(user)
```

运行

```sh
mix run priv/repo/seeds.exs
```
