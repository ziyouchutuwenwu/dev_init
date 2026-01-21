# dev 下迁移

一般用来建表, 修改表结构, 也可以做其它事情, 支持任意代码

## 用法

### 创建

以下命令会创建一个 timestamps_xxx.ex 的文件, 如果需要修改顺序, 可以改时间戳, 越小的执行的越早

```sh
mix ecto.gen.migration xxx
```

格式如下

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

可以拆分为

```elixir
def up do
  # 这里写修改的语句
end

def down do
  # 这里写回退的语句
end
```

### 执行

```sh
mix ecto.migrate
```

执行 sql

```elixir
def up do
  execute "create table users(id serial PRIMARY_KEY, username text)"
end
```

### 查看

查看所有

```sh
mix ecto.migrations
```

### 执行部分

执行一系列 migration, 参数对应的 migration 的 up 方法会被执行

```sh
mix ecto.migrate --to 20211220000835
```

前进 x 步，会调用 up 方法

```sh
mix ecto.migrate --step 2
```

### 回滚

```sh
mix ecto.rollback --all
```

回退一系列 migration, 参数对应的 migration 的 down 方法会被执行

```sh
mix ecto.rollback --to 20211220000835
```

回退 x 步，会调用 down 方法

```sh
mix ecto.rollback --step 2
```

### 打印 sql

打印具体 migration 的 log，一般情况下，使用这个来看调试信息

```sh
mix ecto.migrate --log-migrations-sql
```

打印 `迁移器` 的一些 log

```sh
mix ecto.migrate --log-migrator-sql
```
