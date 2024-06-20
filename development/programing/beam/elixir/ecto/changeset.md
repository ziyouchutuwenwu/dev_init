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
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string

    timestamps()
  end

  def validate(person, params) do
    person
    |> cast(params, [:name, :email])
    |> validate_required([:name, :email])
    |> _demo_validation()
  end

  @demo_names ["aaa", "bbb", "ccc"]
  defp _demo_validation(changeset) do
    name = get_field(changeset, :name)

    if name in @demo_names do
      changeset
    else
      add_error(changeset, :name, "name not correct")
    end
  end
end
```

lib/demo.ex

```elixir
defmodule Demo do
  def demo do
    alias OrmDemo.{User, Repo}
    user = %User{}
    user |> User.validate(%{"name" => "bbb", "email" => "aaa@xxx.com"}) |> Repo.insert()
  end
end
```

### 测试持久化

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```

```elixir
Demo.demo()
```
