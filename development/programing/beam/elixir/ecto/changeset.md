# changeset

## 说明

- changeset
  changeset 是带有数据变更信息和校验规则的容器。
  它只是纯内存结构，不写数据库。
  要保存数据库，需要手动 Repo.insert/update/delete

- schema struct
  对应数据库表字段，类型和表严格绑定。
  不适合直接用于纯内存验证或表单验证，因为输入结构和数据库表不一定一致。

- embedded_schema struct
  纯内存 struct，可用来做表单或 api 输入的验证。
  它不对应数据库表，常用做前置验证，最后可以把验证通过的数据映射到 schema struct，再写入数据库。

## 例子

### 准备

参考 [测试项目模板](./模板/测试项目模板.md)

### migration

创建

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

### schema

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

  def changeset1(user, attrs) do
    user
    |> Changeset.cast(attrs, [:name, :email])
    |> Changeset.validate_required([:name, :email])
    |> Changeset.validate_length(:name, min: 3)
    |> Changeset.validate_format(:email, ~r/@/)
  end

  @names ["name_aaa", "name_bbb", "name_ccc"]
  def changeset2(user, attrs) do
    changeset =
      user
      |> Changeset.cast(attrs, [:name, :email])
      |> Changeset.validate_required([:name, :email])

    name = Changeset.get_field(changeset, :name)

    if name in @names do
      changeset
    else
      Changeset.add_error(changeset, :name, "name not correct")
    end
  end
end
```

### embedded_schema

```elixir
defmodule Accounts do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:age, :integer)
  end

  def changeset(%Accounts{} = accounts, attrs) do
    accounts
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end
end
```

在 phoenix 下可以

```sh
mix phx.gen.embedded Accounts name:string age:integer
```

lib/demo.ex

```elixir
defmodule Demo do
  alias OrmDemo.User
  alias OrmDemo.Repo
  alias Ecto.Changeset
  require Logger

  def schema_demo1() do
    user = %User{name: "xxx", email: "xxx@xxx.com"}
    changeset = user |> User.changeset1(%{name: "zzzzzzz", email: "无法通过的 email"})
    Logger.debug(inspect(changeset.valid?))

    user |> Changeset.change(%{email: "任意 email 都能通过"}) |> Repo.insert()
  end

  def schema_demo2 do
    user = %User{}
    user |> User.changeset2(%{name: "ccc", email: "aaa@xxx.com"})

    # |> Repo.insert()
  end

  def embedded_schema_demo() do
    account = %Accounts{name: "aaa", age: 22}
    changeset = account |> Accounts.changeset(%{name: "bbb", age: 30})

    Logger.debug("valid? #{changeset.valid?}")

    if changeset.valid? do
      data = Changeset.apply_changes(changeset)
      user_attrs = %{name: data.name, age: data.age}

      %User{}
      |> User.changeset1(user_attrs)
      |> Repo.insert()
    else
      {:error, changeset.errors}
    end
  end
end
```

### 测试

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```

```elixir
Demo.schema_demo1
Demo.schema_demo2
Demo.embedded_schema_demo
```
