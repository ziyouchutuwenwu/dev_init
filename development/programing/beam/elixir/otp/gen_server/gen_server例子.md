# gen_server 例子

直接贴例子

## 代码

qps_gen_server.ex

```elixir
defmodule QpsGenServer do
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def get_qps_info_by_ip(ip) do
    GenServer.call(__MODULE__, {:get_qps_info_by_ip, ip})
  end

  def update_ip_qps_info(ip, {accecc_time, count}) do
    GenServer.cast(__MODULE__, {:update_ip_qps_info, {ip, {accecc_time, count}}})
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def async_stop do
    GenServer.cast(__MODULE__, :stop)
  end

  # --------------------------------------------------------------------------------------------------
  def init(state) do
    Qps.init_table()
    {:ok, state}
  end

  def handle_call({:get_qps_info_by_ip, ip}, _from, state) do
    result = Qps.get_qps_info_by_ip(ip)
    {:reply, result, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, "server stopped", state}
  end

  def handle_cast({:update_ip_qps_info, {ip, {accecc_time, count}}}, state) do
    Qps.update_ip_qps_info(ip, {accecc_time, count})
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, _state) do
    Qps.delete_table()
    Logger.debug("reason #{inspect(reason)} in terminate")
  end
end
```

qps.ex

```elixir
defmodule Qps do
  require Logger

  @qps_max 100

  def limitation_reached?(ip) do
    time = DateTime.utc_now()

    case get_qps_info_by_ip(ip) do
      {prev, count} ->
        now = DateTime.utc_now()
        elapsed = DateTime.diff(now, prev, :millisecond)

        if elapsed <= 1000 and elapsed > 0 do
          qps = count / (elapsed / 1000)

          if qps >= @qps_max do
            true
          else
            false
          end
        else
          update_ip_qps_info(ip, {time, count + 1})
          false
        end

      _ ->
        update_ip_qps_info(ip, {time, 1})
        false
    end
  end

  def init_table() do
    :ets.new(:qps, [:set, :named_table])
  end

  def delete_table() do
    :ets.delete(:qps)
  end

  def get_qps_info_by_ip(ip) do
    case :ets.lookup(:qps, ip) do
      [{_, {prev, count}}] ->
        {prev, count}

      [] ->
        {}
    end
  end

  def update_ip_qps_info(ip, {accecc_time, count}) do
    :ets.insert(:qps, {ip, {accecc_time, count}})
  end
end
```

demo.ex

```elixir
defmodule Demo do
  require Logger

  def demo() do
    QpsGenServer.start_link([])

    time = DateTime.utc_now()
    ip = "192.168.1.100"
    QpsGenServer.update_ip_qps_info(ip, {time, 100})

    :timer.sleep(500)

    is_limited = Qps.limitation_reached?(ip)
    Logger.debug(is_limited)
  end
end
```
