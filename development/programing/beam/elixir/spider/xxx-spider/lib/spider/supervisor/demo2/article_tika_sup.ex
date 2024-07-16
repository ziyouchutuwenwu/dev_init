defmodule Demo2.ArticleTikaSup do
  use DynamicSupervisor
  alias Demo2.ArticleTikaSpider

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(type_map, entity_map, file_bin) do
    child_spec = %{
      id: ArticleTikaSpider,
      start: {ArticleTikaSpider, :start_link, [type_map, entity_map, file_bin]},
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
      max_restarts: 30,
      max_seconds: 60,
      max_children: 10,

      # 加上这行，就和 erlang一样，在 start_child 的时候，会把 start_link 的参数一起带过去
      # 允许的域名
      extra_arguments: []
    )
  end
end
