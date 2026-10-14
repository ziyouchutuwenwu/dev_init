defmodule Web.DataSync do
  require Logger

  def sync_to_gateway(
        gateway_url,
        streams,
        callback_url \\ "",
        cooldown_sec \\ 1,
        timeout_sec \\ 3
      ) do
    clean_gateway_url = to_string(gateway_url || "") |> String.trim()

    if clean_gateway_url == "" do
      {:error, "网关地址未配置"}
    else
      target_url = String.trim_trailing(clean_gateway_url, "/") <> "/api/streams"

      parsed_cooldown =
        case cooldown_sec do
          nil ->
            1

          v when is_integer(v) ->
            v

          v when is_binary(v) ->
            case Integer.parse(String.trim(v)) do
              {n, _} -> n
              _ -> 1
            end

          _ ->
            1
        end

      parsed_timeout =
        case timeout_sec do
          nil ->
            3

          v when is_integer(v) ->
            v

          v when is_binary(v) ->
            case Integer.parse(String.trim(v)) do
              {n, _} -> n
              _ -> 3
            end

          _ ->
            3
        end

      payload = %{
        alert: %{
          url: to_string(callback_url || ""),
          cooldown_sec: parsed_cooldown,
          timeout_sec: parsed_timeout
        },
        alert_callback_url: to_string(callback_url || ""),
        alert_cooldown_sec: parsed_cooldown,
        alert_timeout_sec: parsed_timeout,
        streams:
          Enum.map(streams, fn s ->
            id =
              Map.get(s, :stream_id) || Map.get(s, "stream_id") || Map.get(s, :id) ||
                Map.get(s, "id")

            url =
              Map.get(s, :rtsp_url) || Map.get(s, "rtsp_url") || Map.get(s, :url) ||
                Map.get(s, "url")

            enabled =
              case Map.get(s, :enabled) do
                nil ->
                  case Map.get(s, "enabled") do
                    nil -> true
                    val -> val not in [false, "false", 0, "0"]
                  end

                val ->
                  val not in [false, "false", 0, "0"]
              end

            %{id: to_string(id), url: to_string(url), enabled: enabled}
          end)
      }

      Logger.info(
        "[data_sync] pushing #{length(payload.streams)} streams to gateway: #{target_url}"
      )

      try do
        case Req.post(target_url, json: payload, receive_timeout: 5000) do
          {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
            Logger.info("[data_sync] successfully synced streams to gateway")
            sync_all_zones(clean_gateway_url, streams)
            {:ok, body}

          {:ok, %Req.Response{status: status, body: body}} ->
            Logger.error("[data_sync] gateway responded with http #{status}: #{inspect(body)}")
            {:error, "网关响应异常 (HTTP #{status})"}

          {:error, exception} ->
            Logger.error(
              "[data_sync] failed to connect to gateway: #{Exception.message(exception)}"
            )

            {:error, "无法连接网关 (#{Exception.message(exception)})"}
        end
      rescue
        e ->
          Logger.error("[data_sync] failed to connect to gateway: #{Exception.message(e)}")
          {:error, "无法连接网关 (#{Exception.message(e)})"}
      end
    end
  end

  def sync_zone_to_gateway(gateway_url, stream_id, zone_cfg_str) do
    target_url = String.trim_trailing(gateway_url, "/") <> "/api/zone/#{stream_id}"

    case Req.post(target_url,
           body: zone_cfg_str,
           headers: [{"content-type", "application/json"}],
           receive_timeout: 3000
         ) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        Logger.info(
          "[data_sync] successfully hot-reloaded zone for stream #{stream_id} on gateway"
        )

        :ok

      res ->
        Logger.warning("[data_sync] sync zone for stream #{stream_id} returned: #{inspect(res)}")

        :error
    end
  rescue
    e ->
      Logger.warning(
        "[data_sync] failed to connect to gateway for zone sync: #{Exception.message(e)}"
      )

      :error
  end

  def sync_all_zones(gateway_url, streams) do
    Enum.each(streams, fn s ->
      id =
        Map.get(s, :stream_id) || Map.get(s, "stream_id") || Map.get(s, :id) || Map.get(s, "id")

      zone_cfg = Map.get(s, :zone_config) || Map.get(s, "zone_config")

      enabled =
        case Map.get(s, :enabled) do
          nil ->
            case Map.get(s, "enabled") do
              nil -> true
              val -> val not in [false, "false", 0, "0"]
            end

          val ->
            val not in [false, "false", 0, "0"]
        end

      if id && zone_cfg && is_binary(zone_cfg) && String.trim(zone_cfg) != "" do
        synced_cfg =
          case Jason.decode(zone_cfg) do
            {:ok, map} when is_map(map) ->
              Jason.encode!(Map.put(map, "enabled", enabled))

            _ ->
              zone_cfg
          end

        sync_zone_to_gateway(gateway_url, id, synced_cfg)
      end
    end)
  end
end
