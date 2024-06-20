defmodule Demo1.ArticleListSup do
  use DynamicSupervisor
  alias Demo1.ArticleListSpider
  alias Demo1.ArticleSup

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(type_map, url) do
    child_spec = %{
      id: ArticleListSpider,
      start: {ArticleListSpider, :start_link, [type_map, url]},
      shutdown: 5000,
      restart: :transient,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 60,
      max_restarts: 30,
      # 根据实际需求，如果同类型的爬虫分类比较多，则这里尽量大一些
      max_children: 100,

      # 加上这行，就和 erlang一样，在子进程的 start_link 方法里，这个会作为第一个参数传过去
      extra_arguments: [
        %{
          "article_list_sup" => __MODULE__,
          "article_sup" => ArticleSup
        }
      ]
    )
  end
end
