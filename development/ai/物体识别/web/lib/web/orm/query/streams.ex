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
          enabled = if Map.has_key?(item, "enabled"), do: item["enabled"] != false, else: true

          %{
            stream_id: String.trim(to_string(id)),
            rtsp_url: String.trim(to_string(url)),
            title: String.trim(to_string(title)),
            enabled: enabled,
            position: idx
          }
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
            case existing |> Stream.changeset(attrs) |> Repo.update() do
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
