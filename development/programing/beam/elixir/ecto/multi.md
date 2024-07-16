# multi

## 说明

用于 transaction

## 例子

### 准备工作

参考 [测试项目模板](测试项目模板.md)

### 配置 timex

mix.exs

```elixir
{:timex, "~> 3.0"}
```

### time_helper

lib/helper/time_helper.ex

```elixir
defmodule TimeHelper do
  def local_time do
    Timex.now("Asia/Shanghai") |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  end

  def str_to_time(time_str) do
    Timex.parse!(time_str, "%Y-%m-%d %H:%M:%S", :strftime)
  end
end
```

### 创建 post 表

```sh
mix ecto.gen.migration create_post
```

priv/repo/migrations/xxxxx_create_post.exs

```elixir
def change do
  create table(:posts) do
    add :header, :string
    add :body, :string

    timestamps()
  end
end
```

### 创建 post model

lib/orm_demo/post.ex

```elixir
defmodule OrmDemo.Post do
  use Ecto.Schema

  schema "posts" do
    field :header, :string
    field :body, :string

    timestamps()
  end
end
```

### 测试代码

```elixir
defmodule Demo do
  require Logger
  alias OrmDemo.{Repo, Post}
  import Ecto.Query

  def insert1 do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert1, %Post{header: "insert1 header1", body: "insert1 body1"})
    |> Ecto.Multi.insert(:insert2, %Post{header: "insert1 header2", body: "insert1 body2"})
    |> Repo.transaction()
  end

  def insert2 do
    posts_to_insert = [
      %{
        header: "批量插入 header2",
        body: "批量插入 body2",
        inserted_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time(),
        updated_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time()
      },
      %{
        header: "批量插入 header3",
        body: "批量插入 body3",
        inserted_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time(),
        updated_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time()
      },
      %{
        header: "批量插入 header4",
        body: "批量插入 body4",
        inserted_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time(),
        updated_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time()
      },
      %{
        header: "批量插入 header5",
        body: "批量插入 body5",
        inserted_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time(),
        updated_at: "2013-03-05 11:12:13" |> TimeHelper.str_to_time()
      }
    ]

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:insert_all, Post, posts_to_insert)
    |> Repo.transaction()
  end

  def update1 do
    post = Repo.get!(Post, 2)
    changeset = Ecto.Changeset.change(post, header: "更新1")

    Ecto.Multi.new()
    |> Ecto.Multi.update(:update, changeset)
    |> Repo.transaction()
  end

  def update2 do
    posts_to_update = from(p in Post, where: p.id > 1)

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:update_all, posts_to_update,
      set: [header: "batch header", body: "batch body"]
    )
    |> Repo.transaction()
  end

  def delete1 do
    post = Repo.get!(Post, 1)

    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete, post)
    |> Repo.transaction()
  end

  def delete2 do
    posts_to_delete = from(p in Post, where: p.id > 1)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:delete_all, posts_to_delete)
    |> Repo.transaction()
  end

  def run do
    Ecto.Multi.new()
    |> Ecto.Multi.put("header", "1111111")
    |> Ecto.Multi.put("body", "22222222")
    |> Ecto.Multi.run(:batch_run, fn _repo, changes ->
      query =
        from(p in Post,
          where: p.id > 1
        )

      Logger.debug("_changes #{inspect(changes)}")

      case Repo.update_all(query,
             set: [header: changes |> Map.get("header"), body: changes |> Map.get("body")]
           ) do
        {count, _} ->
          {:ok, count}

        _ ->
          {:error, "更新失败"}
      end
    end)
    |> Repo.transaction()
  end
end
```

### 测试

```sh
mix ecto.drop; mix ecto.create; mix ecto.migrate --log-migrations-sql; iex -S mix
```
