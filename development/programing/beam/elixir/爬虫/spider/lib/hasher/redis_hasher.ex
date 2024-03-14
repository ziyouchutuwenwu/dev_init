defmodule Hasher.RedisHasher do
  require Logger
  use GenServer

  def start_link(redis_host, redis_port, passwd, redis_db_number) do
    GenServer.start_link(__MODULE__, [redis_host, redis_port, passwd, redis_db_number],
      name: __MODULE__
    )
  end

  def init([redis_host, redis_port, passwd, redis_db_number]) do
    {:ok, conn} =
      if String.length(passwd) == 0 do
        Redix.start_link(
          host: redis_host,
          port: redis_port,
          database: redis_db_number,
          sync_connect: true
        )
      else
        Redix.start_link(
          host: redis_host,
          port: redis_port,
          password: passwd,
          database: redis_db_number,
          sync_connect: true
        )
      end

    Logger.info("redis hasher started, conn #{inspect(conn)}")
    {:ok, conn}
  end

  def handle_call({:get_hash, url}, _from, state = conn) do
    {:ok, hash_value} = Redix.command(conn, ["get", url])
    {:reply, hash_value, state}
  end

  def handle_cast({:set_hash, {url, hash_value}}, state = conn) do
    Redix.command(conn, ["set", url, hash_value])
    {:noreply, state}
  end
end
