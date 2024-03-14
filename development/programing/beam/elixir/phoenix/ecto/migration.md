# migration

用来建表，修改表结构等

## 说明

### 默认执行

```sh
mix ecto.migrate
```

默认的 `migration` 脚本格式如下

```elixir
def change do
  create table(:access_info) do
    add :user_id, :string
    add :ip, :string, null: false
    add :action_name, :string, null: false
    add :access_time, :naive_datetime, null: false

    timestamps()
  end
end
```

可以改成

```elixir
def up do
  xxx
end
```

### 执行 sql 语句

```elixir
def up do
  execute "CREATE TABLE users(id serial PRIMARY_KEY, username text)"
end
```

### 查看所有 migration

```sh
mix ecto.migrations
```

### 执行到某个 migration

```sh
mix ecto.migrate --to 20211220000835
```

### 执行若干次 migration

后面的数字表示针对当前位置 **前进 x 步**

```sh
mix ecto.migrate --step 2
```

### 回滚若干次

migration 脚本修改 `down` 方法

```elixir
def down do
  xxx
end
```

后面的数字表示针对当前位置 **倒退 x 步**

```sh
mix ecto.rollback --step 2
```

### 打印 sql 语句

打印具体 migration 的 log，一般情况下，使用这个来看调试信息

```sh
mix ecto.migrate --log-migrations-sql
```

打印 `迁移器` 的一些 log

```sh
mix ecto.migrate --log-migrator-sql
```
