defmodule WebWeb.ConfigLive do
  use WebWeb, :live_view

  alias Web.PageStore
  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams
  alias Web.DataSync

  @impl true
  def mount(_params, _session, socket) do
    streams =
      case PageStore.get(:streams) do
        nil -> Streams.list_streams()
        [] -> Streams.list_streams()
        list when is_list(list) -> list
      end
      |> Enum.map(&normalize_stream/1)

    socket =
      socket
      |> assign(:page_title, "视觉检测 - 系统配置")
      |> assign(:active_tab, :config)
      |> assign_new(:gateway_url, fn ->
        PageStore.get(:gateway_url, Settings.get_gateway_url() || "")
      end)
      |> assign_new(:alert_callback_url, fn ->
        PageStore.get(:alert_callback_url, Settings.get_alert_callback_url() || "")
      end)
      |> assign_new(:alert_cooldown_sec, fn ->
        PageStore.get(:alert_cooldown_sec, Settings.get_alert_cooldown_sec() || "1")
      end)
      |> assign_new(:alert_timeout_sec, fn ->
        PageStore.get(:alert_timeout_sec, Settings.get_alert_timeout_sec() || "3")
      end)
      |> assign(:config_streams, streams)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    streams = parse_streams(params["streams"], socket.assigns.config_streams)

    {:noreply,
     socket
     |> assign(:gateway_url, params["gateway_url"] || socket.assigns.gateway_url)
     |> assign(
       :alert_callback_url,
       params["alert_callback_url"] || socket.assigns.alert_callback_url
     )
     |> assign(
       :alert_cooldown_sec,
       params["alert_cooldown_sec"] || socket.assigns.alert_cooldown_sec
     )
     |> assign(
       :alert_timeout_sec,
       params["alert_timeout_sec"] || socket.assigns.alert_timeout_sec
     )
     |> assign(:config_streams, streams)}
  end

  @impl true
  def handle_event("add_stream", _params, socket) do
    count = length(socket.assigns.config_streams) + 1

    new_stream = %{
      stream_id: "stream_#{count}",
      rtsp_url: "rtsp://192.168.88.20:8554/live",
      title: "通道 #{count}: stream_#{count}",
      enabled: true,
      position: count,
      zone_config: nil
    }

    {:noreply, assign(socket, :config_streams, socket.assigns.config_streams ++ [new_stream])}
  end

  @impl true
  def handle_event("remove_stream", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    updated = List.delete_at(socket.assigns.config_streams, idx)
    {:noreply, assign(socket, :config_streams, updated)}
  end

  @impl true
  def handle_event("save_global", params, socket) do
    gateway_url = (params["gateway_url"] || socket.assigns.gateway_url || "") |> String.trim()

    alert_callback_url =
      (params["alert_callback_url"] || socket.assigns.alert_callback_url || "") |> String.trim()

    alert_cooldown_sec =
      (params["alert_cooldown_sec"] || socket.assigns.alert_cooldown_sec || "1") |> String.trim()

    alert_timeout_sec =
      (params["alert_timeout_sec"] || socket.assigns.alert_timeout_sec || "3") |> String.trim()

    raw_streams = parse_streams(params["streams"], socket.assigns.config_streams)

    case validate_streams(raw_streams) do
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}

      :ok ->
        Settings.set_gateway_url(gateway_url)
        Settings.set_alert_callback_url(alert_callback_url)
        Settings.set_alert_cooldown_sec(alert_cooldown_sec)
        Settings.set_alert_timeout_sec(alert_timeout_sec)

        case Streams.replace_all_streams(raw_streams) do
          {:ok, saved_streams} ->
            PageStore.put(:gateway_url, gateway_url)
            PageStore.put(:alert_callback_url, alert_callback_url)
            PageStore.put(:alert_cooldown_sec, alert_cooldown_sec)
            PageStore.put(:alert_timeout_sec, alert_timeout_sec)
            PageStore.put(:streams, saved_streams)
            PageStore.put(:stream_list, Enum.filter(saved_streams, &(&1.enabled != false)))

            Phoenix.PubSub.broadcast(
              Web.PubSub,
              "config_updated",
              {:config_updated, gateway_url, saved_streams, alert_callback_url,
               alert_cooldown_sec, alert_timeout_sec}
            )

            case DataSync.sync_to_gateway(
                   gateway_url,
                   saved_streams,
                   alert_callback_url,
                   alert_cooldown_sec,
                   alert_timeout_sec
                 ) do
              {:ok, _} ->
                {:noreply,
                 socket
                 |> assign(:gateway_url, gateway_url)
                 |> assign(:config_streams, Enum.map(saved_streams, &normalize_stream/1))
                 |> put_flash(:info, "保存成功，已同步到硬件网关")}

              {:error, sync_err} ->
                {:noreply,
                 socket
                 |> assign(:gateway_url, gateway_url)
                 |> assign(:config_streams, Enum.map(saved_streams, &normalize_stream/1))
                 |> put_flash(:info, "已保存到本地数据库，但硬件网关未同步: #{sync_err}")}
            end

          {:error, db_err} ->
            {:noreply, put_flash(socket, :error, "保存失败: #{inspect(db_err)}")}
        end
    end
  end

  @impl true
  def handle_info(
        {:config_updated, gateway_url, streams, callback_url, cooldown, timeout},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:gateway_url, gateway_url)
     |> assign(:alert_callback_url, callback_url)
     |> assign(:alert_cooldown_sec, cooldown)
     |> assign(:alert_timeout_sec, timeout)
     |> assign(:config_streams, Enum.map(streams, &normalize_stream/1))}
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}

  defp validate_streams([]), do: {:error, "请至少保留一路流"}

  defp validate_streams(streams) do
    Enum.reduce_while(streams, {MapSet.new(), :ok}, fn stream, {seen, _} ->
      id = String.trim(to_string(stream.stream_id || ""))
      url = String.trim(to_string(stream.rtsp_url || ""))

      cond do
        id == "" ->
          {:halt, {:error, "流标识不能为空"}}

        not Regex.match?(~r/^[a-zA-Z0-9_\-]+$/, id) ->
          {:halt, {:error, "流标识格式不合法（仅支持字母、数字、下划线、短横线）"}}

        MapSet.member?(seen, id) ->
          {:halt, {:error, "流标识重复: #{id}"}}

        url == "" ->
          {:halt, {:error, "rtsp 流地址不能为空"}}

        true ->
          {:cont, {MapSet.put(seen, id), :ok}}
      end
    end)
    |> case do
      {_, :ok} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_streams(nil, current), do: current

  defp parse_streams(map, current) when is_map(map) do
    map
    |> Enum.sort_by(fn {k, _} ->
      case Integer.parse(to_string(k)) do
        {n, _} -> n
        _ -> 0
      end
    end)
    |> Enum.map(fn {idx_str, attrs} ->
      idx =
        case Integer.parse(to_string(idx_str)) do
          {n, _} -> n
          _ -> 0
        end

      orig = Enum.at(current, idx) || %{}
      normalize_stream(Map.merge(orig, attrs))
    end)
  end

  defp parse_streams(list, _) when is_list(list), do: Enum.map(list, &normalize_stream/1)

  defp normalize_stream(%Web.Orm.Entity.Stream{} = s) do
    %{
      stream_id: s.stream_id,
      rtsp_url: s.rtsp_url,
      title: s.title || "通道 #{s.position}: #{s.stream_id}",
      enabled: s.enabled,
      position: s.position,
      zone_config: s.zone_config
    }
  end

  defp normalize_stream(map) when is_map(map) do
    id =
      cond do
        Map.has_key?(map, "stream_id") -> map["stream_id"]
        Map.has_key?(map, :stream_id) -> map[:stream_id]
        Map.has_key?(map, "id") -> map["id"]
        Map.has_key?(map, :id) -> map[:id]
        true -> ""
      end

    url =
      cond do
        Map.has_key?(map, "rtsp_url") -> map["rtsp_url"]
        Map.has_key?(map, :rtsp_url) -> map[:rtsp_url]
        Map.has_key?(map, "url") -> map["url"]
        Map.has_key?(map, :url) -> map[:url]
        true -> ""
      end

    pos = Map.get(map, :position) || Map.get(map, "position") || 1
    title = Map.get(map, :title) || Map.get(map, "title") || "通道: #{id}"

    enabled =
      if Map.has_key?(map, "enabled"),
        do: map["enabled"] != false,
        else: Map.get(map, :enabled, true) != false

    zone = Map.get(map, :zone_config) || Map.get(map, "zone_config")

    %{
      stream_id: to_string(id),
      rtsp_url: to_string(url),
      title: to_string(title),
      enabled: enabled,
      position: pos,
      zone_config: zone
    }
  end
end
