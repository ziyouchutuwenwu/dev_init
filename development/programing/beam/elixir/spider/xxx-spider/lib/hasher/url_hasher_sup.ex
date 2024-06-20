defmodule Hasher.UrlHasherSup do
  alias Hasher.UrlHasher

  use Supervisor

  def start_link() do
    redis_host = ConfigFetcher.get_redis_host()
    redis_port = ConfigFetcher.get_redis_port()
    redis_passwd = ConfigFetcher.get_redis_passwd()
    redis_db = ConfigFetcher.get_redis_db()

    Supervisor.start_link(__MODULE__, [redis_host, redis_port, redis_passwd, redis_db],
      name: __MODULE__
    )
  end

  def init([redis_host, redis_port, passwd, redis_db_number]) do
    children = [
      %{
        id: UrlHasher,
        start: {UrlHasher, :start_link, [redis_host, redis_port, passwd, redis_db_number]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
