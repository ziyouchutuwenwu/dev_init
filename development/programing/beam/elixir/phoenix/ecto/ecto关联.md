# ecto 关联

## 准备工作

创建项目, `--sup` 的意思是，带有 supervisor

```sh
mix new demo --sup
```

修改依赖 mix.exs

```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.4"},
    {:postgrex, ">= 0.0.0"},
    {:myxql, ">= 0.0.0"}
  ]
end
```

创建 repo

```sh
mix ecto.gen.repo -r OrmDemo.Repo
```

修改 `lib/orm_demo/repo.ex`

```elixir
defmodule OrmDemo.Repo do
  use Ecto.Repo,
    otp_app: :demo,
    adapter: Ecto.Adapters.MyXQL
end
```

config/config.exs

```elixir
import Config

config :demo, OrmDemo.Repo,
  database: "demo_repo",
  username: "root",
  password: "root",
  hostname: "localhost",
  port: 4407

config :demo, ecto_repos: [OrmDemo.Repo]
```

`lib/demo/application.ex`

```elixir
def start(_type, _args) do
  children = [
    {OrmDemo.Repo, []}
  ]

  opts = [strategy: :one_for_one, name: Demo.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## 注意

migration 内可以设置外键的约束模式，具体见 [这里](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#references/2)

## one to one

### 关键字说明

belongs_to 用于表里面的 **外键字段**, has_one 仅用于语义, 也就是说, belongs_to 应当用于 **关键字段为外键** 的表里面

### 例子

一个 User, 一个 Avatar

### 基础工作

```sh
mix ecto.gen.migration create_user
```

修改 `priv/repo/migrations/*_create_user.exs`

```elixir
def change do
  create table(:users) do
    add :name, :string
    add :email, :string
  end
end
```

手动创建 `lib/orm_demo/user.ex`

```elixir
defmodule OrmDemo.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
  end
end
```

```sh
mix ecto.gen.migration create_avatar
```

修改 `priv/repo/migrations/*_create_avatar.exs`

```elixir
def change do
  create table(:avatars) do
    add :nick_name, :string
    add :pic_url, :string
  end
end
```

手动创建 `lib/orm_demo/avatar.ex`

```elixir
defmodule OrmDemo.Avatar do
  use Ecto.Schema

  schema "avatars" do
    field :nick_name, :string
    field :pic_url, :string
  end
end
```

### 增加关联关系

```sh
mix ecto.gen.migration avatar_belongs_to_user
```

修改 `priv/repo/migrations/*_avatar_belongs_to_user.exs`

```elixir
def change do
  alter table(:avatars) do
    # 在子表里面增加外键, 后面的参数和db里面的约束一致，级联删除和更新，操作主键表，外键表也受影响
    add :user_id, references(:users, column: :id, on_update: :update_all, on_delete: :delete_all)
  end
end
```

修改映射类 `lib/orm_demo/avatar.ex` 和 `lib/orm_demo/user.ex`

```elixir
defmodule OrmDemo.Avatar do
  use Ecto.Schema

  schema "avatars" do
    field :nick_name, :string
    field :pic_url, :string
    belongs_to :user, OrmDemo.User
  end
end


defmodule OrmDemo.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    has_one :avatar, OrmDemo.Avatar
  end
end
```

### 持久化测试

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql
iex -S mix
```

```elixir
alias OrmDemo.{Repo, User, Avatar}

avatar = %Avatar{nick_name: "avatar1", pic_url: "http://elixir-lang.org/images/logo.png"}
user = %User{name: "user1", email: "user1@example.com", avatar: avatar}
user = Repo.insert!(user)
```

验证

```elixir
Repo.all(User) |> Repo.preload(:avatar)
```

## one to many

### 关键字

belongs_to 用于表里面的 **外键字段**, has_many 仅用于语义, 也就是说, belongs_to 应当用于 **关键字段为外键** 的表里面

### 例子说明

例子为一个 User 多个 Post

### 基础准备工作

USER 在之前做过了, 忽略

创建 migration

```sh
mix ecto.gen.migration create_post
```

修改 `priv/repo/migrations/*_create_post.exs`

```elixir
def change do
  create table(:posts) do
    add :header, :string
    add :body, :string
  end
end
```

创建 `lib/orm_demo/post.ex`

```elixir
defmodule OrmDemo.Post do
  use Ecto.Schema

  schema "posts" do
    field :header, :string
    field :body, :string
  end
end
```

### 增加关联

```sh
mix ecto.gen.migration post_belongs_to_user
```

修改内容 `priv/repo/migrations/*_post_belongs_to_user.exs`

```elixir
def change do
  alter table(:posts) do
    add :user_id, references(:users, column: :id, on_delete: :delete_all, on_update: :update_all)
  end
end
```

修改 posts 的 schema `lib/orm_demo/post.ex`

```elixir
defmodule OrmDemo.Post do
  use Ecto.Schema

  schema "posts" do
    field :header, :string
    field :body, :string
    belongs_to :user, OrmDemo.User
  end
end
```

修改 user 表的 schema `lib/orm_demo/user.ex`

```elixir
defmodule OrmDemo.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    has_many :posts, OrmDemo.Post
  end
end
```

### 持久化

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql
iex -S mix
```

```elixir
alias OrmDemo.{Repo, User, Post}

user = %User{name: "user1", email: "user1@example.com"}
user = Repo.insert!(user)

post = Ecto.build_assoc(user, :posts, %{header: "post header 1", body: "post body 1"})
Repo.insert!(post)

post = Ecto.build_assoc(user, :posts, %{header: "post header 2", body: "post body 2"})
Repo.insert!(post)
```

## many to many

### 场景例子

例子为 Post 和 Tag

### 准备

Post 在之前做过了, 忽略

```sh
mix ecto.gen.migration create_tag
```

修改 `priv/repo/migrations/*create_tag.exs`

```elixir
def change do
  create table(:tags) do
    add :name, :string
  end
end
```

手动创建模型 `lib/orm_demo/tag.ex`

```elixir
defmodule OrmDemo.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string
  end
end
```

### 关联

```sh
mix ecto.gen.migration create_posts_tags
```

修改 `priv/repo/migrations/*_create_posts_tags`

```elixir
def change do
  create table(:posts_tags) do
    add :tag_id, references(:tags, column: :id)
    add :post_id, references(:posts, column: :id, on_update: :update_all, on_delete: :delete_all)
  end

  # 这个是多字段联合索引
  create unique_index(:posts_tags, [:tag_id, :post_id])
end
```

修改 `lib/orm_demo/post.ex`

```elixir
defmodule OrmDemo.Post do
  use Ecto.Schema

  schema "posts" do
    field :header, :string
    field :body, :string
    many_to_many :tags, OrmDemo.Tag, join_through: "posts_tags"
  end
end
```

修改 `lib/orm_demo/tag.ex`

```elixir
defmodule OrmDemo.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string
    many_to_many :posts, OrmDemo.Post, join_through: "posts_tags"
  end
end
```

### 测试持久化

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql
iex -S mix
```

先创建一些 tag

```elixir
alias OrmDemo.{Repo, Tag, Post}
tag1 = Repo.insert! %Tag{name: "tag1"}
tag2 = Repo.insert! %Tag{name: "tag2"}
tag3 = Repo.insert! %Tag{name: "tag3"}
```

再创建一些 post

```elixir
post = %Post{header: "header1", body: "body1"}
post = Repo.insert!(post)
```

关联起来

```elixir
post = Repo.preload(post, [:tags])
post_changeset = Ecto.Changeset.change(post)
post_with_tags = Ecto.Changeset.put_assoc(post_changeset, :tags, [tag1, tag2])
post = Repo.update!(post_with_tags)
```
