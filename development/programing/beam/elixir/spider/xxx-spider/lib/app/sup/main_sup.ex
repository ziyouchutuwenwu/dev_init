defmodule MainSup do
  alias Hasher.UrlHasherSup
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      # redis hasher
      %{
        id: UrlHasherSup,
        start: {UrlHasherSup, :start_link, []},
        type: :supervisor
      },
      # 需要预先启动的爬虫 supervisor
      %{
        id: PreStartedSpiderSup,
        start: {PreStartedSpiderSup, :start_link, []},
        type: :supervisor
      },
      # 爬虫
      %{
        id: SpiderSup,
        start: {SpiderSup, :start_link, []},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
