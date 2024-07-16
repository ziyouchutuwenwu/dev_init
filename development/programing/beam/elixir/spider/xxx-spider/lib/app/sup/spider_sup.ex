defmodule SpiderSup do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      %{
        id: Spider,
        start: {Spider, :start_link, []},
        restart: :temporary,
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
