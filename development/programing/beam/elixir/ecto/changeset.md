# changeset

一般用于数据验证

## 例子

### 准备工作

参考 [测试项目模板](测试项目模板.md)

### 创建 migration

user 的 migration

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

### 自定义验证

lib/orm_demo/user.ex

```elixir
defmodule OrmDemo.User do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "users" do
    field(:name, :string)
    field(:email, :string)

    timestamps()
  end

  @demo_names ["aaa", "bbb", "ccc"]
  def custom_change(user, params) do
    changeset =
      user
      |> Changeset.cast(params, [:name, :email])
      |> Changeset.validate_required([:name, :email])

    name = Changeset.get_field(changeset, :name)

    if name in @demo_names do
      changeset
    else
      Changeset.add_error(changeset, :name, "name not correct")
    end
  end
end
```

lib/demo.ex

```elixir
defmodule Demo do
  alias OrmDemo.User
  alias Ecto.Changeset

  def demo1() do
    user = %User{name: "xxx", email: "xxx@xxx.com"}
    user |> Changeset.change(email: "aaaaaaaaaaaaaaa")
    user |> Changeset.change(%{email: "bbbbbbbbbbbbb"})
  end

  def demo2 do
    user = %User{}
    user |> User.custom_change(%{name: "mmc", email: "aaa@xxx.com"})
  end
end
```

### 测试持久化

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```

```elixir
Demo.demo1
Demo.demo2
```
