# ecto 基础

## 步骤

### 准备工作

创建项目

```sh
mix phx.new hello --no-assets --database mysql
```

查看项目数据库的适配器

```sh
lib/hello/repo.ex
```

### 检查配置

修改 config/dev.exs

```elixir
config :hello, Hello.Repo,
  username: "root",
  password: "root",
  database: "hello_dev",
  hostname: "localhost",
  port: 4407,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### 建库

```sh
mix ecto.create
```

### 生成 model

`lib/项目名` 的 ecto 目录下，创建 user 模块，表结构为 my_user

`priv/repo/migrations` 下，创建了 migration

```sh
mix phx.gen.schema Ecto.User my_user name:string email:string bio:string number_of_pets:integer
```

### migration

创建

```sh
mix ecto.gen.migration create_user
```

修改 `priv/repo/migrations` 下的 `migration`

```sh
mix ecto.migrate
```

### model 验证

`lib/hello` 下, model 的 changeset 里面做验证

### 数据持久化

```elixir
alias Hello.Repo
alias Hello.Ecto.User

Repo.insert(%User{email: "user1@example.com"})
Repo.all(User)
```

```elixir
import Ecto.Query
Repo.all(from u in User, select: u.email)

Repo.one(from u in User, where: like(u.email, "%1%"), select: count(u.id))
Repo.all(from u in User, select: %{u.id => u.email})
```
