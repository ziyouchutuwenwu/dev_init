# rbac

## 说明

一个例子

## 步骤

### 结构

| table | colume | colume |
| ----- | ------ | ------ |
| users | id     | name   |

| table | colume | colume |
| ----- | ------ | ------ |
| roles | id     | name   |

| table       | colume | colume |
| ----------- | ------ | ------ |
| permissions | id     | name   |

| table      | colume  | colume  |
| ---------- | ------- | ------- |
| user_roles | user_id | role_id |

| table             | colume  | colume        |
| ----------------- | ------- | ------------- |
| roles_permissions | role_id | permission_id |

### 创建模板

参考 [测试项目模板](测试项目模板.md)

### 建基础表

用户表

```sh
mix ecto.gen.migration create_users
```

```elixir
def change do
  create table(:users) do
    add :name, :string
    add :password, :string

    timestamps()
  end
end
```

角色表

```sh
mix ecto.gen.migration create_roles
```

```elixir
def change do
  create table(:roles) do
    add :name, :string
    add :desc, :string

    timestamps()
  end
end
```

权限表

```sh
mix ecto.gen.migration create_permissions
```

```elixir
def change do
  create table(:permissions) do
    add :name, :string
    add :desc, :string

    timestamps()
  end
end
```

### 创建关联

```sh
mix ecto.gen.migration create_roles_users
```

```elixir
def change do
  create table(:roles_users) do
    add :role_id, references(:roles, column: :id)
    add :user_id, references(:users, column: :id), on_update: :update_all, on_delete: :delete_all
  end

  # 这个是多字段联合索引
  create unique_index(:roles_users, [:role_id, :user_id])
end
```

```sh
mix ecto.gen.migration create_roles_roles_permissions
```

```elixir
def change do
  create table(:roles_permissions) do
    add :role_id, references(:roles, column: :id)
    add :permission_id, references(:permissions, column: :id), on_update: :update_all, on_delete: :delete_all
  end

  # 这个是多字段联合索引
  create unique_index(:roles_permissions, [:role_id, :permission_id])
end
```

lib/orm_demo/permission.ex

```elixir
defmodule OrmDemo.Permission do
  use Ecto.Schema
  alias OrmDemo.Role

  schema "permissions" do
    field(:name, :string)
    field(:desc, :string)

    timestamps()

    many_to_many(:roles, Role, join_through: "roles_permissions")
  end
end
```

lib/orm_demo/role.ex

```elixir
defmodule OrmDemo.Role do
  use Ecto.Schema
  alias OrmDemo.{User, Permission}

  schema "roles" do
    field :name, :string
    field :desc, :string

    timestamps()

    many_to_many(:permissions, Permission, join_through: "roles_permissions")
    many_to_many(:users, User, join_through: "roles_users")
  end
end
```

lib/orm_demo/user.ex

```elixir
defmodule OrmDemo.User do
  use Ecto.Schema
  alias OrmDemo.Role

  schema "users" do
    field :name, :string
    field :password, :string

    timestamps()

    many_to_many(:roles, Role, join_through: "roles_users")
  end
end
```

### seeds 数据

priv/repo/seeds.exs

```elixir
defmodule Demo.Seeds do
  alias OrmDemo.{Repo, User, Role, Permission}

  def init_role_permissions() do
    permission1 = %Permission{name: "permission1", desc: "permission1 desc"} |> Repo.insert!()
    permission2 = %Permission{name: "permission2", desc: "permission2 desc"} |> Repo.insert!()

    role1 = %Role{name: "role1", desc: "role1 desc"} |> Repo.insert!()
    role2 = %Role{name: "role2", desc: "role2 desc"} |> Repo.insert!()

    # 角色1 和 权限1 对应
    preloaded1 = role1 |> Repo.preload([:permissions])
    changeset1 = Ecto.Changeset.change(preloaded1)

    changeset1 |> Ecto.Changeset.put_assoc(:permissions, [permission1]) |> Repo.update!

    # 权限2 和 角色2 对应
    preloaded2 = role2 |> Repo.preload([:permissions])
    changeset2 = Ecto.Changeset.change(preloaded2)

    changeset2 |> Ecto.Changeset.put_assoc(:permissions, [permission2]) |> Repo.update!
  end


  def init_roles_users do
    user1 = %User{name: "user1"} |> Repo.insert!()
    user2 = %User{name: "user2"} |> Repo.insert!()

    role1 = Repo.get_by!(Role, name: "role1")
    preloaded1 = role1 |> Repo.preload([:users])
    changeset1 = Ecto.Changeset.change(preloaded1)
    changeset1 |> Ecto.Changeset.put_assoc(:users, [user1]) |> Repo.update!

    role2 = Repo.get_by!(Role, name: "role2")
    preloaded2 = role2 |> Repo.preload([:users])
    changeset2 = Ecto.Changeset.change(preloaded2)
    changeset2 |> Ecto.Changeset.put_assoc(:users, [user2]) |> Repo.update!
  end
end

Demo.Seeds.init_role_permissions()
Demo.Seeds.init_roles_users()
```

### 测试

demo.ex

```elixir
defmodule Demo do
  require Logger
  import Ecto.Query
  alias OrmDemo.{Repo, User, Permission}

  def demo do
    has_permission = check_permission("user1", "permission1")
    Logger.debug("has_permission #{inspect(has_permission)}")
  end

  def check_permission(user_name, permission_name) do
    role_from_user_id_query =
      from(user_record in User,
        join: role_record in assoc(user_record, :roles),
        select: %{id: role_record.id},
        where: user_record.name == ^user_name
      )

    role_id_list =
      role_from_user_id_query
      |> Repo.all()
      |> Enum.map(fn %{id: role_id} ->
        role_id
      end)

    query =
      from(permission_record in Permission,
        join: role_record in assoc(permission_record, :roles),
        select: %{name: permission_record.name},
        where: permission_record.id in ^role_id_list
      )

    permission_name_list = query |> Repo.all()

    has_permission =
      permission_name_list
      |> Enum.any?(fn %{name: iter_permission_name} ->
        permission_name == iter_permission_name
      end)

    has_permission
  end
end
```

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate
mix run priv/repo/seeds.exs
```
