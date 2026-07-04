# seeds

## 说明

用于创建预定义数据

## 步骤

priv/repo/seeds/user.exs

```elixir
defmodule AiData.Seeds.User do
  require Logger
  alias AiData.Repo
  alias AiData.Orm.User

  def prepare() do
    pwd = "123456"
    hashed_password = Bcrypt.hash_pwd_salt(pwd)
    Logger.debug("#{inspect(hashed_password)}")
    user = %User{name: "admin", password: hashed_password}
    Repo.insert(user)
  end
end
```

priv/repo/seeds.exs

```elixir
Code.eval_file("priv/repo/seeds/user.exs")

if Mix.env() == :dev do
  AiData.Seeds.User.prepare()
end
```

运行

```sh
mix run priv/repo/seeds.exs
```
