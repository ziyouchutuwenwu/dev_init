# changeset

changeset 在 phoenix 里面，其实代表了数据的一系列走向，包括数据验证，过滤等等

## 不结合数据库的验证

创建

```sh
mix phx.gen.embedded Embedded.User name:string email:string
```

测试

```elixir
alias WebDemo.Embedded.User
params = %{name: "aaa", email: "abc@aaa.com"}
changeset = User.changeset(%User{}, params)
changeset.valid?
changeset.changes
changeset.errors
```

## 结合数据库的验证

### 准备工作

```sh
mix phx.gen.schema Schema.Person person name:string age:integer
```

### 测试数据及更改

```elixir
changeset = Ecto.Changeset.cast(%WebDemo.Schema.Person{}, %{"name" => "aaa"}, [:name, :age])
Ecto.Changeset.validate_required(changeset, [:name, :age])
```

```elixir
params = %{"name" => "aaa"}
changeset = WebDemo.Schema.Person.changeset(%WebDemo.Schema.Person{}, params)
changeset.valid?
changeset.changes
changeset.errors
```

### 自定义验证

#### 代码

lib/web_demo/schema/person.ex

```elixir
defmodule WebDemo.Schema.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "person" do
    field :age, :integer, default: 0
    field :name, :string

    timestamps()
  end

  @demo_names ["aaa", "bbb", "ccc"]
  def my_validation(changeset) do
    name = get_field(changeset, :name)

    if name in @demo_names do
      changeset
    else
      add_error(changeset, :name, "is not a superhero")
    end
  end
  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
    |> my_validation()
  end
end
```

#### 执行

```elixir
WebDemo.Schema.Person.changeset(%WebDemo.Schema.Person{}, %{"name" => "Bob"})
```
