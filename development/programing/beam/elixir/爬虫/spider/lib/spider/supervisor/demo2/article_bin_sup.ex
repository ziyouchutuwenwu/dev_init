defmodule Demo2.ArticleBinSup do
  use DynamicSupervisor
  alias Demo2.ArticleBinSpider

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(type_map, entity_map, url) do
    child_spec = %{
      id: ArticleBinSpider,
      start: {ArticleBinSpider, :start_link, [type_map, entity_map, url]},
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
      max_children: 100,

      # 加上这行，就和 erlang一样，在 start_child 的时候，会把 start_link 的参数一起带过去
      # 允许的域名
      extra_arguments: []
    )
  end
end
