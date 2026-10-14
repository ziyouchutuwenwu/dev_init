defmodule Web.Orm.Query.Streams do
  import Ecto.Query, warn: false
  alias Web.Repo
  alias Web.Orm.Entity.Stream

  def list_streams do
    Stream
    |> order_by([s], asc: s.position, asc: s.id)
    |> Repo.all()
  end

  def list_enabled_streams do
    Stream
    |> where([s], s.enabled == true)
    |> order_by([s], asc: s.position, asc: s.id)
    |> Repo.all()
  end

  def get_stream_by_stream_id(stream_id) do
    Repo.get_by(Stream, stream_id: stream_id)
  end

  def replace_all_streams(stream_params_list) when is_list(stream_params_list) do
    Repo.transaction(fn ->
      normalized_list =
        stream_params_list
        |> Enum.with_index(1)
        |> Enum.map(fn {item, idx} ->
          id = item["id"] || item[:id] || item["stream_id"] || item[:stream_id] || ""
          url = item["url"] || item[:url] || item["rtsp_url"] || item[:rtsp_url] || ""
          title = item["title"] || item[:title] || "通道 #{idx}: #{id}"
          enabled =
            cond do
              Map.has_key?(item, "enabled") ->
                val = item["enabled"]
                val not in [false, "false", 0, "0"]

              Map.has_key?(item, :enabled) ->
                val = item[:enabled]
                val not in [false, "false", 0, "0"]

              true ->
                true
            end

          zone_config =
            cond do
              Map.has_key?(item, "zone_config") -> item["zone_config"]
              Map.has_key?(item, :zone_config) -> item[:zone_config]
              true -> nil
            end

          synced_zone_config =
            cond do
              is_binary(zone_config) and String.trim(zone_config) != "" ->
                case Jason.decode(zone_config) do
                  {:ok, map} when is_map(map) ->
                    if Map.has_key?(map, "enabled") do
                      Jason.encode!(Map.put(map, "enabled", enabled))
                    else
                      zone_config
                    end

                  _ ->
                    zone_config
                end

              is_map(zone_config) ->
                if Map.has_key?(zone_config, "enabled") or Map.has_key?(zone_config, :enabled) do
                  Jason.encode!(Map.put(zone_config, "enabled", enabled))
                else
                  Jason.encode!(zone_config)
                end

              true ->
                nil
            end

          attrs = %{
            stream_id: String.trim(to_string(id)),
            rtsp_url: String.trim(to_string(url)),
            title: String.trim(to_string(title)),
            enabled: enabled,
            position: idx
          }

          if synced_zone_config do
            Map.put(attrs, :zone_config, synced_zone_config)
          else
            attrs
          end
        end)
        |> Enum.reject(fn s -> s.stream_id == "" or s.rtsp_url == "" end)

      new_ids = MapSet.new(Enum.map(normalized_list, & &1.stream_id))

      from(s in Stream, where: s.stream_id not in ^MapSet.to_list(new_ids))
      |> Repo.delete_all()

      for attrs <- normalized_list do
        case Repo.get_by(Stream, stream_id: attrs.stream_id) do
          nil ->
            case %Stream{} |> Stream.changeset(attrs) |> Repo.insert() do
              {:ok, s} -> s
              {:error, cs} -> Repo.rollback(cs)
            end

          existing ->
            updated_attrs =
              if Map.has_key?(attrs, :zone_config) do
                attrs
              else
                case existing.zone_config do
                  str when is_binary(str) and str != "" ->
                    case Jason.decode(str) do
                      {:ok, map} when is_map(map) and :erlang.is_map_key("enabled", map) ->
                        Map.put(attrs, :zone_config, Jason.encode!(Map.put(map, "enabled", attrs.enabled)))

                      _ ->
                        attrs
                    end

                  _ ->
                    attrs
                end
              end

            case existing |> Stream.changeset(updated_attrs) |> Repo.update() do
              {:ok, s} -> s
              {:error, cs} -> Repo.rollback(cs)
            end
        end
      end

      list_streams()
    end)
  end

  def delete_stream_by_id(stream_id) do
    case Repo.get_by(Stream, stream_id: stream_id) do
      nil -> {:ok, nil}
      stream -> Repo.delete(stream)
    end
  end

  def update_stream_enabled(stream_id, enabled) when is_boolean(enabled) do
    case Repo.get_by(Stream, stream_id: stream_id) do
      nil ->
        {:error, :not_found}

      stream ->
        updated_attrs = %{enabled: enabled}

        updated_attrs =
          case stream.zone_config do
            str when is_binary(str) and str != "" ->
              case Jason.decode(str) do
                {:ok, map} when is_map(map) and :erlang.is_map_key("enabled", map) ->
                  Map.put(updated_attrs, :zone_config, Jason.encode!(Map.put(map, "enabled", enabled)))

                _ ->
                  updated_attrs
              end

            _ ->
              updated_attrs
          end

        stream
        |> Stream.changeset(updated_attrs)
        |> Repo.update()
    end
  end

  def update_zone_config(stream_id, zone_config) when is_binary(zone_config) do
    case Repo.get_by(Stream, stream_id: stream_id) do
      nil ->
        {:error, :not_found}

      stream ->
        stream
        |> Stream.changeset(%{zone_config: zone_config})
        |> Repo.update()
    end
  end

  def update_zone_config(stream_id, zone_config_map) when is_map(zone_config_map) do
    case Jason.encode(zone_config_map) do
      {:ok, json_str} -> update_zone_config(stream_id, json_str)
      {:error, reason} -> {:error, reason}
    end
  end
end
