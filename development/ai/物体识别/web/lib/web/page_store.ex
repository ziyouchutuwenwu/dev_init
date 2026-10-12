defmodule Web.PageStore do
  use Agent

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  def start_link(_opts \\ []) do
    Agent.start_link(
      fn ->
        init_state()
      end,
      name: __MODULE__
    )
  end

  def init_state do
    try do
      %{
        gateway_url: Settings.get_gateway_url(),
        alert_callback_url: Settings.get_alert_callback_url(),
        alert_cooldown_sec: Settings.get_alert_cooldown_sec(),
        alert_timeout_sec: Settings.get_alert_timeout_sec(),
        streams: Streams.list_streams(),
        stream_list: Streams.list_enabled_streams()
      }
    rescue
      _ ->
        default_state()
    end
  end

  def default_state do
    %{
      gateway_url: "http://192.168.88.20:8181",
      alert_callback_url: "",
      alert_cooldown_sec: "1",
      alert_timeout_sec: "3",
      streams: [],
      stream_list: []
    }
  end

  def get(key, default \\ nil) do
    ensure_started()

    Agent.get(__MODULE__, fn data ->
      Map.get(data, key, default)
    end)
  end

  def put(key, value) do
    ensure_started()

    Agent.update(__MODULE__, fn data ->
      Map.put(data, key, value)
    end)
  end

  def update(fun) when is_function(fun, 1) do
    ensure_started()

    Agent.update(__MODULE__, fun)
  end

  def all do
    ensure_started()

    Agent.get(__MODULE__, & &1)
  end

  def reload do
    ensure_started()

    Agent.update(__MODULE__, fn _data ->
      init_state()
    end)
  end

  def reset do
    ensure_started()

    Agent.update(__MODULE__, fn _data ->
      init_state()
    end)
  end

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil ->
        case start_link([]) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
        end

      _pid ->
        :ok
    end
  end
end
