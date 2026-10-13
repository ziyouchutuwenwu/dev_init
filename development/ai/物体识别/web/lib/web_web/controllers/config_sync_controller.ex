defmodule WebWeb.ConfigSyncController do
  use WebWeb, :controller

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams
  alias Web.DataSync


  def save_local(conn, params) do
    if url = params["gateway_url"] do
      Settings.set_gateway_url(url)
    end

    if Map.has_key?(params, "alert_callback_url") do
      Settings.set_alert_callback_url(params["alert_callback_url"])
    end

    if Map.has_key?(params, "alert_cooldown_sec") do
      Settings.set_alert_cooldown_sec(params["alert_cooldown_sec"])
    end

    if Map.has_key?(params, "alert_timeout_sec") do
      Settings.set_alert_timeout_sec(params["alert_timeout_sec"])
    end

    gateway_url = Settings.get_gateway_url()
    alert_callback_url = Settings.get_alert_callback_url()
    alert_cooldown_sec = Settings.get_alert_cooldown_sec()
    alert_timeout_sec = Settings.get_alert_timeout_sec()

    case save_streams_if_present(params["streams"]) do
      {:ok, streams} ->
        json(conn, %{
          success: true,
          message: "保存成功",
          gateway_url: gateway_url,
          alert_callback_url: alert_callback_url,
          alert_cooldown_sec: alert_cooldown_sec,
          alert_timeout_sec: alert_timeout_sec,
          streams: serialize_streams(streams)
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, message: "保存失败: #{inspect(reason)}"})
    end
  end

  def sync_to_hardware(conn, params) do
    if url = params["gateway_url"] do
      Settings.set_gateway_url(url)
    end

    if Map.has_key?(params, "alert_callback_url") do
      Settings.set_alert_callback_url(params["alert_callback_url"])
    end

    if Map.has_key?(params, "alert_cooldown_sec") do
      Settings.set_alert_cooldown_sec(params["alert_cooldown_sec"])
    end

    if Map.has_key?(params, "alert_timeout_sec") do
      Settings.set_alert_timeout_sec(params["alert_timeout_sec"])
    end

    gateway_url = Settings.get_gateway_url()
    alert_callback_url = Settings.get_alert_callback_url()
    alert_cooldown_sec = Settings.get_alert_cooldown_sec()
    alert_timeout_sec = Settings.get_alert_timeout_sec()

    case save_streams_if_present(params["streams"]) do
      {:ok, streams} ->
        case DataSync.sync_to_gateway(
               gateway_url,
               streams,
               alert_callback_url,
               alert_cooldown_sec,
               alert_timeout_sec
             ) do
          {:ok, _res} ->
            json(conn, %{
              success: true,
              hardware_synced: true,
              message: "保存成功，已同步到硬件网关",
              gateway_url: gateway_url,
              alert_callback_url: alert_callback_url,
              alert_cooldown_sec: alert_cooldown_sec,
              alert_timeout_sec: alert_timeout_sec,
              streams: serialize_streams(streams)
            })

          {:error, reason} ->
            json(conn, %{
              success: true,
              hardware_synced: false,
              message: "已保存到本地数据库，但网关同步失败: #{reason}",
              gateway_url: gateway_url,
              alert_callback_url: alert_callback_url,
              alert_cooldown_sec: alert_cooldown_sec,
              alert_timeout_sec: alert_timeout_sec,
              streams: serialize_streams(streams)
            })
        end

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          hardware_synced: false,
          message: "保存失败: #{inspect(reason)}",
          gateway_url: gateway_url,
          streams: serialize_streams(Streams.list_streams())
        })
    end
  end

  def get_zone(conn, %{"stream_id" => stream_id}) do
    case Streams.get_stream_by_stream_id(stream_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "stream not found"})

      stream ->
        cfg =
          case stream.zone_config do
            nil ->
              nil

            str when is_binary(str) ->
              case Jason.decode(str) do
                {:ok, val} -> val
                _ -> str
              end
          end

        json(conn, %{stream_id: stream_id, config: cfg})
    end
  end

  def save_zone(conn, %{"stream_id" => stream_id} = params) do
    raw_cfg = params["config"] || params["zone_config"] || Map.drop(params, ["stream_id"])

    zone_str =
      case raw_cfg do
        str when is_binary(str) -> str
        map when is_map(map) -> Jason.encode!(map)
        _ -> "{}"
      end

    case Streams.update_zone_config(stream_id, zone_str) do
      {:ok, stream} ->
        gateway_url = Settings.get_gateway_url()

        gateway_synced =
          if is_binary(gateway_url) && String.trim(gateway_url) != "" do
            DataSync.sync_zone_to_gateway(gateway_url, stream_id, zone_str) == :ok
          else
            false
          end

        json(conn, %{
          success: true,
          stream_id: stream.stream_id,
          zone_config: stream.zone_config,
          gateway_synced: gateway_synced
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  defp save_streams_if_present(nil), do: {:ok, Streams.list_streams()}

  defp save_streams_if_present(streams) when is_list(streams),
    do: Streams.replace_all_streams(streams)

  defp save_streams_if_present(_), do: {:ok, Streams.list_streams()}

  def serialize_streams(streams) do
    Enum.map(streams, fn s ->
      %{
        id: s.stream_id,
        stream_id: s.stream_id,
        title: s.title,
        url: s.rtsp_url,
        rtsp_url: s.rtsp_url,
        enabled: s.enabled,
        position: s.position,
        zone_config: s.zone_config
      }
    end)
  end
end
