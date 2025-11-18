# prod 下迁移

## 说明

没有 elixir 的环境下，prod 模式下，可以直接用这个跑脚本, 版本号不要带引号

当然也可以写 seeds 进去

## 例子

```elixir
defmodule WebDemo.DB do

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def migrate_to(version) do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, to: version))
    end
  end

  def rollback_to(version) do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    end
  end

  defp repos do
    app = get_app_name()
    Application.fetch_env!(app, :ecto_repos)
  end

  defp load_app do
    app = get_app_name()
    Application.load(app)

    Application.put_env(app, :minimal, true)
    Application.ensure_all_started(app)
  end

  defp get_app_name do
    config = Mix.Project.config()
    config[:app]
  end
end
```
