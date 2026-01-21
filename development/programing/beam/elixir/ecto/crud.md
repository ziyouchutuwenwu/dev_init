# crud

## 说明

带自定义时间戳

## 例子

### 准备工作

参考 [测试项目模板](测试项目模板.md)

### 配置 timex

mix.exs

```elixir
{:timex, "~> 3.0"}
```

### time_helper

lib/helper/time_helper.ex

```elixir
defmodule TimeHelper do
  def local_time do
    Timex.now("Asia/Shanghai") |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  end

  def str_to_time(time_str) do
    Timex.parse!(time_str, "%Y-%m-%d %H:%M:%S", :strftime)
  end
end
```

### 时间戳宏

lib/orm_demo/schema.ex

```elixir
defmodule OrmDemo.Schema do
  defmacro __using__(_env) do
    quote do
      use Ecto.Schema
      @timestamps_opts [type: :naive_datetime, autogenerate: {TimeHelper, :local_time, []}]
    end
  end
end
```

### 创建表和模型

#### 创建 user 表

```sh
mix ecto.gen.migration create_user
```

priv/repo/migrations/xxxxx_create_user.exs

```elixir
def change do
  create table(:users) do
    add :name, :string
    add :email, :string

    timestamps()
  end
end
```

#### 创建 user model

lib/orm_demo/user.ex

```elixir
defmodule OrmDemo.User do
  # 使用宏引入时间戳
  use OrmDemo.Schema

  schema "users" do
    field :name, :string
    field :email, :string

    timestamps()
  end
end
```

#### 创建 post 表

```sh
mix ecto.gen.migration create_post
```

priv/repo/migrations/xxxxx_create_post.exs

```elixir
def change do
  create table(:posts) do
    add :header, :string
    add :body, :string

    timestamps()
  end
end
```

#### 创建 post model

lib/orm_demo/post.ex

```elixir
defmodule OrmDemo.Post do
  # 使用宏引入时间戳
  use OrmDemo.Schema

  schema "posts" do
    field :header, :string
    field :body, :string

    timestamps()
  end
end
```

#### 关联关系

```sh
mix ecto.gen.migration posts_belongs_to_user
```

priv/repo/migrations/xxxxx_posts_belongs_to_user.exs

```elixir
def change do
  alter table(:posts) do
    # 在子表里面增加外键, 主表更新删除时候, 设置外键表的对应行为
    add :user_id, references(:users, column: :id, on_update: :update_all, on_delete: :delete_all)
  end
end
```

或者手动添加字段，不使用外键

```elixir
def change do
  alter table(:posts) do
    add :user_id, :bigint
  end
  create index(:posts, [:user_id])
end
```

lib/orm_demo/post.ex

```elixir
defmodule OrmDemo.Post do
  # 使用宏引入时间戳
  use OrmDemo.Schema
  alias OrmDemo.User

  schema "posts" do
    field :header, :string
    field :body, :string

    belongs_to :user, User

    timestamps()
  end
end
```

lib/orm_demo/user.ex

```elixir
defmodule OrmDemo.User do
  # 使用宏引入时间戳
  use OrmDemo.Schema
  alias OrmDemo.Post

  schema "users" do
    field :name, :string
    field :email, :string

    has_many :posts, Post

    timestamps()
  end
end
```

### 测试代码

```elixir
defmodule Demo do
  alias OrmDemo.{Repo, User, Post}
  import Ecto.Query

  # 先插入主表数据, 再插入外键表数据
  def insert1 do
    user = %User{name: "user_000", email: "user_000@xxx.com"}
    user = Repo.insert!(user)

    %Post{
      header: "header_111",
      body: "body_111",
      user: user
    }
    |> Repo.insert!()
  end

  # 先插入主表数据, 再构造关联数据, 插入从表
  def insert2 do
    user = %User{name: "user_000", email: "user_000@xxx.com"}
    user = Repo.insert!(user)

    # user = Repo.get_by!(User, name: "user_000")

    user
    |> Ecto.build_assoc(:posts, header: "header_000", body: "body_000")
    |> Repo.insert()

    user
    |> Ecto.build_assoc(:posts, header: "header_111", body: "body_000")
    |> Repo.insert()
  end

  def insert3 do
    user1 = %User{name: "user_111", email: "user_111@xxx.com"}
    Repo.insert!(user1)

    user2 = %User{
      name: "user1",
      email: "user1@xxx.com",
      inserted_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time(),
      updated_at: "2063-03-05 11:12:13" |> TimeHelper.str_to_time()
    }

    Repo.insert!(user2)

    ts = TimeHelper.local_time()

    users =
      [
        %{name: "user2", email: "user2@xxx.com"},
        %{name: "user3", email: "user3@xxx.com"},
        %{name: "user4", email: "user4@xxx.com"},
        %{name: "user5", email: "user5@xxx.com"},
        %{name: "user6", email: "user6@xxx.com"},
        %{name: "user7", email: "user7@xxx.com"},
        %{name: "user8", email: "user8@xxx.com"}
      ]
      |> Enum.map(fn row ->
        row
        |> Map.put(:inserted_at, ts)
        |> Map.put(:updated_at, ts)
      end)

    # insert_all 不会插入时间戳
    Repo.insert_all(User, users)
  end

  def get1 do
    # User 有多个 post, 因此拿到 user 以后, 需要 preload 一下
    # users = Repo.all(User) |> Repo.preload(:posts)
    Repo.get_by!(User, name: "user8") |> Repo.preload(:posts)
  end

  def get2 do
    query =
      from(post_record in Post,
        join: user_record in assoc(post_record, :user),
        where: like(post_record.header, ^"%000%"),
        where: post_record.id > 1,
        # select: [post_record.name, post_record.id],
        limit: 3,
        offset: 0
      )

    Repo.all(query) |> Repo.preload(:user)
  end

  def update1() do
    user = Repo.get_by(User, name: "user5")
    user |> Ecto.Changeset.change(%{name: "aaaaaaa"}) |> Repo.update()
  end

  def update2() do
    query =
      from(p in Post,
        where: p.id > 1
      )

    Repo.update_all(query, set: [header: "ccccccc", body: "dddddddddd"])
  end

  def delete1() do
    user = Repo.get(User, 1)
    user |> Repo.delete()
  end

  def delete2() do
    query =
      from(user_record in User,
        where: user_record.id > 1,
        select: user_record.id
      )

    ids_to_delete = Repo.all(query) |> List.flatten()

    from(user_record in User, where: user_record.id in ^ids_to_delete) |> Repo.delete_all()
  end
end
```

### 测试

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```
