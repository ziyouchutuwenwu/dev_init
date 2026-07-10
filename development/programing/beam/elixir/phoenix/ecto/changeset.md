# changeset

## 说明

- changeset
  changeset 是带验证的的数据变更器。
  不写库。

- schema
  写库需要 Repo.insert/update/delete

- embedded_schema
  不写库。

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

phoenix 下，自动生成

```sh
mix phx.gen.embedded Accounts name:string age:integer
```

lib/demo.ex

```elixir
defmodule Demo do
  alias OrmDemo.User
  alias OrmDemo.Repo
  alias Ecto.Changeset
  alias Accounts
  require Logger

  def prepare do
    %User{}
    |> Changeset.cast(%{name: "prepare", email: "prepare@prepare.com"}, [:name, :email])
    |> Repo.insert!()
  end

  def all do
    Repo.all(User)
  end

  def demo1 do
    user = %User{}
    changeset = user |> User.changeset1(%{name: "demo1", email: "demo1@demo1.com"})
    Logger.debug("demo1 valid? #{changeset.valid?}")
  end

  def demo2 do
    user = %User{}
    changeset = user |> User.changeset2(%{name: "demo2", email: "demo2@demo2.com"})
    Logger.debug("demo2 valid? #{changeset.valid?}")
  end

  def demo3 do
    user = Repo.get!(User, 1)
    user |> User.update_to_db(Repo, %{email: "demo3@demo3.com"})
  end

  def demo4 do
    user = Repo.get!(User, 1)
    user |> User.update_to_mem(%{name: "demo4", email: "demo4@demo4.com"})
  end

  def demo5 do
    %Accounts{name: "aaa", age: 22} |> Accounts.update_to_mem(%{name: "bbb", age: 30})
  end
end
```

### 测试

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```
