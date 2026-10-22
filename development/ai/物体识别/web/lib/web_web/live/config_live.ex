defmodule WebWeb.ConfigLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams
  alias Web.DataSync

  @impl true
  def mount(_params, _session, socket) do
    streams =
      case Streams.list_streams() do
        [] ->
          [
            %{
              stream_id: "stream_1",
              rtsp_url: "rtsp://192.168.88.20:8554/live",
              title: "通道 1: stream_1",
              enabled: true,
              position: 1,
              model: "industry",
              selected_classes: Web.ModelLoader.default_classes_for_model("industry"),
              zone_config: nil
            }
          ]

        list ->
          Enum.map(list, &normalize_stream/1)
      end

    current_idx = 0
    current_stream = Enum.at(streams, current_idx)
    active_model = current_stream.model || "industry"
    all_classes = Web.ModelLoader.classes_for_model(active_model)
    selected_classes = current_stream.selected_classes || Web.ModelLoader.default_classes_for_model(active_model)
    all_models = Web.ModelLoader.load_model_label_info()

    socket =
      socket
      |> assign(:page_title, "视觉检测 - 系统配置")
      |> assign(:active_tab, :config)
      |> assign(:gateway_url, Settings.get_gateway_url() || "")
      |> assign(:alert_callback_url, Settings.get_alert_callback_url() || "")
      |> assign(:alert_cooldown_sec, Settings.get_alert_cooldown_sec() || "1")
      |> assign(:alert_timeout_sec, Settings.get_alert_timeout_sec() || "3")
      |> assign(:config_streams, streams)
      |> assign(:current_stream_idx, current_idx)
      |> assign(:all_models, all_models)
      |> assign(:active_model, active_model)
      |> assign(:all_classes, all_classes)
      |> assign(:selected_classes, selected_classes)
      |> assign(:class_search, "")
      |> assign(:matched_class_ids, MapSet.new())

    {:ok, socket}
  end

  @impl true
  def handle_event("select_stream_to_config", %{"index" => idx_str}, socket) do
    idx =
      case Integer.parse(idx_str) do
        {n, _} -> max(0, min(n, length(socket.assigns.config_streams) - 1))
        _ -> 0
      end

    stream = Enum.at(socket.assigns.config_streams, idx)
    model = stream.model || "industry"
    classes = Web.ModelLoader.classes_for_model(model)
    selected = stream.selected_classes || Web.ModelLoader.default_classes_for_model(model)
    matched = compute_matched_ids(classes, socket.assigns.class_search)

    {:noreply,
     socket
     |> assign(:current_stream_idx, idx)
     |> assign(:active_model, model)
     |> assign(:all_classes, classes)
     |> assign(:selected_classes, selected)
     |> assign(:matched_class_ids, matched)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    streams =
      parse_streams(
        params["streams"] || get_in(params, ["config", "streams"]),
        socket.assigns.config_streams
      )

    # 检查是否有通道的模型被用户切换了，若有则自动将详细配置面板切到该通道
    changed_model_idx =
      Enum.find_index(Enum.with_index(streams), fn {s, i} ->
        old_s = Enum.at(socket.assigns.config_streams, i)
        old_s && to_string(s.model) != to_string(old_s.model)
      end)

    current_idx =
      case changed_model_idx do
        nil ->
          max(0, min(socket.assigns.current_stream_idx, max(0, length(streams) - 1)))

        idx ->
          idx
      end

    current_stream = Enum.at(streams, current_idx)
    active_model = (current_stream && current_stream.model) || "industry"
    classes = Web.ModelLoader.classes_for_model(active_model)
    selected = (current_stream && current_stream.selected_classes) || Web.ModelLoader.default_classes_for_model(active_model)

    class_search =
      case params["class_search"] do
        nil -> socket.assigns.class_search
        val -> String.trim(val)
      end

    matched_ids = compute_matched_ids(classes, class_search)

    {:noreply,
     socket
     |> assign(:gateway_url, params["gateway_url"] || get_in(params, ["config", "gateway_url"]) || socket.assigns.gateway_url)
     |> assign(
       :alert_callback_url,
       params["alert_callback_url"] || get_in(params, ["config", "alert_callback_url"]) || socket.assigns.alert_callback_url
     )
     |> assign(
       :alert_cooldown_sec,
       params["alert_cooldown_sec"] || get_in(params, ["config", "alert_cooldown_sec"]) || socket.assigns.alert_cooldown_sec
     )
     |> assign(
       :alert_timeout_sec,
       params["alert_timeout_sec"] || get_in(params, ["config", "alert_timeout_sec"]) || socket.assigns.alert_timeout_sec
     )
     |> assign(:config_streams, streams)
     |> assign(:current_stream_idx, current_idx)
     |> assign(:active_model, active_model)
     |> assign(:all_classes, classes)
     |> assign(:selected_classes, selected)
     |> assign(:class_search, class_search)
     |> assign(:matched_class_ids, matched_ids)}
  end

  @impl true
  def handle_event("search_classes", params, socket) do
    query =
      case params do
        %{"value" => v} -> v
        %{"class_search" => v} -> v
        %{"query" => v} -> v
        _ -> ""
      end
      |> String.trim()

    matched = compute_matched_ids(socket.assigns.all_classes, query)

    {:noreply,
     socket
     |> assign(:class_search, query)
     |> assign(:matched_class_ids, matched)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:class_search, "")
     |> assign(:matched_class_ids, MapSet.new())}
  end

  @impl true
  def handle_event("toggle_class", %{"id" => class_id}, socket) do
    idx = socket.assigns.current_stream_idx
    streams = socket.assigns.config_streams

    case Enum.at(streams, idx) do
      nil ->
        {:noreply, socket}

      stream ->
        current = stream.selected_classes || []

        updated_classes =
          if class_id in current do
            List.delete(current, class_id)
          else
            current ++ [class_id]
          end

        updated_stream = Map.put(stream, :selected_classes, updated_classes)
        updated_streams = List.replace_at(streams, idx, updated_stream)

        {:noreply,
         socket
         |> assign(:config_streams, updated_streams)
         |> assign(:selected_classes, updated_classes)}
    end
  end

  @impl true
  def handle_event("select_all_classes", _params, socket) do
    idx = socket.assigns.current_stream_idx
    streams = socket.assigns.config_streams

    case Enum.at(streams, idx) do
      nil ->
        {:noreply, socket}

      stream ->
        all = Enum.map(socket.assigns.all_classes, & &1.id)
        updated_stream = Map.put(stream, :selected_classes, all)
        updated_streams = List.replace_at(streams, idx, updated_stream)

        {:noreply,
         socket
         |> assign(:config_streams, updated_streams)
         |> assign(:selected_classes, all)}
    end
  end

  @impl true
  def handle_event("clear_all_classes", _params, socket) do
    idx = socket.assigns.current_stream_idx
    streams = socket.assigns.config_streams

    case Enum.at(streams, idx) do
      nil ->
        {:noreply, socket}

      stream ->
        updated_stream = Map.put(stream, :selected_classes, [])
        updated_streams = List.replace_at(streams, idx, updated_stream)

        {:noreply,
         socket
         |> assign(:config_streams, updated_streams)
         |> assign(:selected_classes, [])}
    end
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
      model: "industry",
      selected_classes: Web.ModelLoader.default_classes_for_model("industry"),
      zone_config: nil
    }

    updated_streams = socket.assigns.config_streams ++ [new_stream]
    new_idx = length(updated_streams) - 1

    classes = Web.ModelLoader.classes_for_model("industry")
    matched = compute_matched_ids(classes, socket.assigns.class_search)

    {:noreply,
     socket
     |> assign(:config_streams, updated_streams)
     |> assign(:current_stream_idx, new_idx)
     |> assign(:active_model, "industry")
     |> assign(:all_classes, classes)
     |> assign(:selected_classes, new_stream.selected_classes)
     |> assign(:matched_class_ids, matched)}
  end

  @impl true
  def handle_event("remove_stream", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    streams = socket.assigns.config_streams

    if length(streams) <= 1 do
      {:noreply, put_flash(socket, :error, "请至少保留一路摄像头通道")}
    else
      updated = List.delete_at(streams, idx)
      new_idx = max(0, min(socket.assigns.current_stream_idx, length(updated) - 1))
      current_stream = Enum.at(updated, new_idx)
      model = current_stream.model || "industry"
      classes = Web.ModelLoader.classes_for_model(model)
      selected = current_stream.selected_classes || Web.ModelLoader.default_classes_for_model(model)
      matched = compute_matched_ids(classes, socket.assigns.class_search)

      {:noreply,
       socket
       |> assign(:config_streams, updated)
       |> assign(:current_stream_idx, new_idx)
       |> assign(:active_model, model)
       |> assign(:all_classes, classes)
       |> assign(:selected_classes, selected)
       |> assign(:matched_class_ids, matched)}
    end
  end

  @impl true
  def handle_event("save_global", params, socket) do
    gateway_url =
      (params["gateway_url"] || get_in(params, ["config", "gateway_url"]) || socket.assigns.gateway_url || "")
      |> String.trim()

    alert_callback_url =
      (params["alert_callback_url"] || get_in(params, ["config", "alert_callback_url"]) || socket.assigns.alert_callback_url || "")
      |> String.trim()

    alert_cooldown_sec =
      (params["alert_cooldown_sec"] || get_in(params, ["config", "alert_cooldown_sec"]) || socket.assigns.alert_cooldown_sec || "1")
      |> String.trim()

    alert_timeout_sec =
      (params["alert_timeout_sec"] || get_in(params, ["config", "alert_timeout_sec"]) || socket.assigns.alert_timeout_sec || "3")
      |> String.trim()

    raw_streams =
      parse_streams(
        params["streams"] || get_in(params, ["config", "streams"]),
        socket.assigns.config_streams
      )

    case validate_streams(raw_streams) do
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}

      :ok ->
        Settings.set_gateway_url(gateway_url)
        Settings.set_alert_callback_url(alert_callback_url)
        Settings.set_alert_cooldown_sec(alert_cooldown_sec)
        Settings.set_alert_timeout_sec(alert_timeout_sec)

        # 按照各路通道各自绑定的 AI 模型，分别写入独立的 target_classes 与 rules
        updated_streams =
          Enum.map(raw_streams, fn s ->
            model = s[:model] || s["model"] || "industry"
            classes_for_this = s[:selected_classes] || Web.ModelLoader.default_classes_for_model(model)
            current_zone = s[:zone_config] || s["zone_config"]

            new_zone =
              case Jason.decode(current_zone || "{}") do
                {:ok, m} when is_map(m) ->
                  m
                  |> Map.put("model", model)
                  |> Map.put("target_classes", classes_for_this)
                  |> Map.put_new("rules", [])
                  |> Map.put("enabled", s[:enabled])
                  |> Jason.encode!()

                _ ->
                  Jason.encode!(%{
                    "model" => model,
                    "target_classes" => classes_for_this,
                    "rules" => [],
                    "enabled" => s[:enabled]
                  })
              end

            s
            |> Map.put(:model, model)
            |> Map.put(:selected_classes, classes_for_this)
            |> Map.put(:zone_config, new_zone)
          end)

        case Streams.replace_all_streams(updated_streams) do
          {:ok, saved_streams} ->
            pid = self()

            Task.start(fn ->
              res =
                DataSync.sync_to_gateway(
                  gateway_url,
                  saved_streams,
                  alert_callback_url,
                  alert_cooldown_sec,
                  alert_timeout_sec
                )

              send(pid, {:gateway_sync_result, res})
            end)

            normalized_saved = Enum.map(saved_streams, &normalize_stream/1)
            current_idx = max(0, min(socket.assigns.current_stream_idx, length(normalized_saved) - 1))
            current_stream = Enum.at(normalized_saved, current_idx)

            {:noreply,
             socket
             |> assign(:gateway_url, gateway_url)
             |> assign(:config_streams, normalized_saved)
             |> assign(:current_stream_idx, current_idx)
             |> assign(:active_model, current_stream.model)
             |> assign(:selected_classes, current_stream.selected_classes)
             |> put_flash(:info, "正在保存各通道垂直模型与检测配置...")}

          {:error, db_err} ->
            {:noreply, put_flash(socket, :error, "保存失败: #{inspect(db_err)}")}
        end
    end
  end

  @impl true
  def handle_info({:gateway_sync_result, {:ok, _}}, socket) do
    Process.send_after(self(), :clear_flash, 3000)
    {:noreply, put_flash(socket, :info, "所有通道检测配置保存成功并已动态生效")}
  end

  def handle_info({:gateway_sync_result, {:error, sync_err}}, socket) do
    Process.send_after(self(), :clear_flash, 4000)
    {:noreply, put_flash(socket, :error, "网关同步异常: #{sync_err}")}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

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
      orig_model = orig[:model] || orig["model"] || "industry"
      new_model = attrs["model"] || attrs[:model] || orig_model

      # 若在下拉框中切换了模型，自动切换选中的类别为新模型的默认类别
      selected_classes =
        cond do
          to_string(new_model) != to_string(orig_model) ->
            Web.ModelLoader.default_classes_for_model(new_model)

          orig[:selected_classes] ->
            orig[:selected_classes]

          orig["selected_classes"] ->
            orig["selected_classes"]

          true ->
            Web.ModelLoader.default_classes_for_model(new_model)
        end

      stream_id = attrs["stream_id"] || attrs[:stream_id] || orig[:stream_id] || orig["stream_id"] || ""
      rtsp_url = attrs["rtsp_url"] || attrs[:rtsp_url] || orig[:rtsp_url] || orig["rtsp_url"] || ""

      enabled =
        cond do
          Map.has_key?(attrs, "enabled") ->
            attrs["enabled"] not in [false, "false", 0, "0"]

          Map.has_key?(attrs, :enabled) ->
            attrs[:enabled] not in [false, "false", 0, "0"]

          Map.has_key?(orig, :enabled) ->
            orig[:enabled] not in [false, "false", 0, "0"]

          true ->
            true
        end

      pos = orig[:position] || orig["position"] || (idx + 1)
      title = orig[:title] || orig["title"] || "通道 #{pos}: #{stream_id}"
      zone = orig[:zone_config] || orig["zone_config"]

      %{
        stream_id: to_string(stream_id),
        rtsp_url: to_string(rtsp_url),
        title: to_string(title),
        enabled: enabled,
        position: pos,
        model: to_string(new_model),
        selected_classes: selected_classes,
        zone_config: zone
      }
    end)
  end

  defp parse_streams(list, _) when is_list(list), do: Enum.map(list, &normalize_stream/1)

  defp normalize_stream(%Web.Orm.Entity.Stream{} = s) do
    model = s.model || "industry"

    selected_classes =
      case Jason.decode(s.zone_config || "{}") do
        {:ok, %{"target_classes" => tc}} when is_list(tc) and length(tc) > 0 ->
          tc

        _ ->
          Web.ModelLoader.default_classes_for_model(model)
      end

    %{
      stream_id: s.stream_id,
      rtsp_url: s.rtsp_url,
      title: s.title || "通道 #{s.position}: #{s.stream_id}",
      enabled: s.enabled,
      position: s.position,
      model: model,
      selected_classes: selected_classes,
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

    pos = Map.get(map, "position") || Map.get(map, :position) || 1
    title = Map.get(map, "title") || Map.get(map, :title) || "通道: #{id}"
    model = Map.get(map, "model") || Map.get(map, :model) || "industry"

    enabled =
      cond do
        Map.has_key?(map, "enabled") ->
          val = map["enabled"]
          val not in [false, "false", 0, "0"]

        Map.has_key?(map, :enabled) ->
          val = map[:enabled]
          val not in [false, "false", 0, "0"]

        true ->
          true
      end

    zone = Map.get(map, :zone_config) || Map.get(map, "zone_config")

    selected_classes =
      cond do
        Map.has_key?(map, :selected_classes) && is_list(map[:selected_classes]) ->
          map[:selected_classes]

        Map.has_key?(map, "selected_classes") && is_list(map["selected_classes"]) ->
          map["selected_classes"]

        is_binary(zone) && zone != "" ->
          case Jason.decode(zone) do
            {:ok, %{"target_classes" => tc}} when is_list(tc) and length(tc) > 0 ->
              tc

            _ ->
              Web.ModelLoader.default_classes_for_model(model)
          end

        true ->
          Web.ModelLoader.default_classes_for_model(model)
      end

    %{
      stream_id: to_string(id),
      rtsp_url: to_string(url),
      title: to_string(title),
      enabled: enabled,
      position: pos,
      model: to_string(model),
      selected_classes: selected_classes,
      zone_config: zone
    }
  end

  defp compute_matched_ids(_classes, ""), do: MapSet.new()

  defp compute_matched_ids(classes, query) when is_binary(query) do
    q = String.downcase(String.trim(query))

    if q == "" do
      MapSet.new()
    else
      classes
      |> Enum.filter(fn cls ->
        String.contains?(String.downcase(cls.name), q) or
          String.contains?(String.downcase(cls.code), q) or
          String.contains?(String.downcase(cls.tag), q)
      end)
      |> Enum.map(& &1.id)
      |> MapSet.new()
    end
  end
end
