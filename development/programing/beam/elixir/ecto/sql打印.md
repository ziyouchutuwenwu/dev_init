# sql 打印

## 显示 sql

### 显示 migration 的 sql

```sh
mix ecto.migrate --log-migrations-sql
```

### 显示查询的 sql

```elixir
# 这个支持复杂查询
Ecto.Adapters.SQL.to_sql(:all, Repo, Post)

# 这个只适用普通查询
Repo.to_sql(:all, Post)
```

例子

```elixir
import Ecto.Query
alias OrmDemo.{Repo, Tag, Post}
require Logger

query = from p in Post
{query, params} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)
Logger.debug("#{query}, #{inspect(params)}")
```

```elixir
import Ecto.Query
alias OrmDemo.{Repo, Tag, Post}

query = from p in Post, select: p.header
Ecto.Adapters.SQL.to_sql(:all, Repo, query)
```

```elixir
import Ecto.Query
alias OrmDemo.{Repo, Tag, Post}

defmodule Demo do
  def print_sql(queryable) do
    IO.inspect(Ecto.Adapters.SQL.to_sql(:all, Repo, queryable))
    queryable
  end

  def list() do
    Post
    |> where([post], post.header != "")
    |> limit(100)
    |> print_sql
    |> Repo.all()
  end
end
```

## 执行 sql

### migration 执行 sql

先 gen 一个 migration

```sh
mix ecto.gen.migration my_database_structure_migration
```

然后修改 migration

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

### 执行 sql 语句

创建项目

```sh
mix phx.new web_demo --no-webpack --database mysql
```

```elixir
Ecto.Adapters.SQL.query(WebDemo.Repo,"show databases",[])
```
