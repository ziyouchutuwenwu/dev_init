# 执行 sql

## 例子

```elixir
defmodule Demo do
  require Logger

  def demo do
    # param_title = "标题"
    # param_category = "分类 1"

    param_title = ""
    param_category = ""

    dynamc_title =
      case param_title do
        "" ->
          %{where: "", param: []}

        _ ->
          %{where: "and title = ?", param: [param_title]}
      end

    dynamc_category =
      case param_category do
        "" ->
          %{where: "", param: []}

        _ ->
          %{where: "and category = ?", param: [param_category]}
      end

    query = """
      select * from articles where 1=1
      #{dynamc_category.where}
      #{dynamc_title.where}
    """

    params = dynamc_title.param ++ dynamc_category.param

    result = Ecto.Adapters.SQL.query(AiData.Repo, query, params)
    Logger.debug("#{inspect(result.rows)}")
  end
end
```
