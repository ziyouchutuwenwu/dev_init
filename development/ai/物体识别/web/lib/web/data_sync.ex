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

          seconds when is_integer(seconds) ->
            seconds

          seconds_str when is_binary(seconds_str) ->
            case Integer.parse(String.trim(seconds_str)) do
              {parsed_seconds, _rest} -> parsed_seconds
              _ -> 1
            end

          _ ->
            1
        end

      parsed_timeout =
        case timeout_sec do
          nil ->
            3

          seconds when is_integer(seconds) ->
            seconds

          seconds_str when is_binary(seconds_str) ->
            case Integer.parse(String.trim(seconds_str)) do
              {parsed_seconds, _rest} -> parsed_seconds
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
          Enum.map(streams, fn stream ->
            id =
              Map.get(stream, :stream_id) || Map.get(stream, "stream_id") || Map.get(stream, :id) ||
                Map.get(stream, "id")

            url =
              Map.get(stream, :rtsp_url) || Map.get(stream, "rtsp_url") || Map.get(stream, :url) ||
                Map.get(stream, "url")

            enabled =
              case Map.get(stream, :enabled) do
                nil ->
                  case Map.get(stream, "enabled") do
                    nil -> true
                    val -> val not in [false, "false", 0, "0"]
                  end

                val ->
                  val not in [false, "false", 0, "0"]
              end

            model =
              Map.get(stream, :model) || Map.get(stream, "model") || ""

            %{id: to_string(id), url: to_string(url), enabled: enabled, model: to_string(model)}
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
        exception ->
          Logger.error("[data_sync] failed to connect to gateway: #{Exception.message(exception)}")
          {:error, "无法连接网关 (#{Exception.message(exception)})"}
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
    exception ->
      Logger.warning(
        "[data_sync] failed to connect to gateway for zone sync: #{Exception.message(exception)}"
      )

      :error
  end

  def sync_all_zones(gateway_url, streams) do
    Task.start(fn ->
      Enum.each(streams, fn stream ->
        id =
          Map.get(stream, :stream_id) || Map.get(stream, "stream_id") || Map.get(stream, :id) ||
            Map.get(stream, "id")

        zone_cfg = Map.get(stream, :zone_config) || Map.get(stream, "zone_config")
        model = Map.get(stream, :model) || Map.get(stream, "model") || ""

        enabled =
          case Map.get(stream, :enabled) do
            nil ->
              case Map.get(stream, "enabled") do
                nil -> true
                val -> val not in [false, "false", 0, "0"]
              end

            val ->
              val not in [false, "false", 0, "0"]
          end

        if id do
          base_cfg =
            if zone_cfg && is_binary(zone_cfg) && String.trim(zone_cfg) != "" do
              zone_cfg
            else
              nil
            end

          synced_cfg =
            case Jason.decode(base_cfg || "{}") do
              {:ok, map} when is_map(map) ->
                classes =
                  if Map.get(map, "model") == model and is_list(Map.get(map, "target_classes")) do
                    map["target_classes"]
                  else
                    Web.ModelLoader.default_classes_for_model(model)
                  end

                map
                |> Map.put("enabled", enabled)
                |> Map.put("model", model)
                |> Map.put("target_classes", classes)
                |> Map.put_new("rules", [])
                |> Jason.encode!()

              _ ->
                Jason.encode!(%{
                  "enabled" => enabled,
                  "model" => model,
                  "target_classes" => Web.ModelLoader.default_classes_for_model(model),
                  "rules" => []
                })
            end

          sync_zone_to_gateway(gateway_url, id, synced_cfg)
          Process.sleep(50)
        end
      end)
    end)
  end
end
