# sql

## 说明

执行 sql

## 用法

migration 执行 sql

```sh
mix ecto.gen.migration my_database_structure_migration
```

```elixir
defmodule My.Database.Structure.Migration do
  use Ecto.Migration

  def up do
    execute File.read!("/path/to/sql_dump.sql")
  end

  def down do
  end
end
```

执行 sql 语句

```elixir
Ecto.Adapters.SQL.query(WebDemo.Repo, "select * from users where id = ?", [1])
```
