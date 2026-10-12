defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.PageStore
  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "视觉检测")
      |> assign(:active_tab, :monitor)
      |> assign_new(:gateway_url, fn ->
        PageStore.get(:gateway_url, Settings.get_gateway_url() || "")
      end)
      |> assign_new(:stream_list, fn ->
        PageStore.get(:stream_list, Streams.list_enabled_streams())
      end)

    {:ok, socket}
  end

  @impl true
  def handle_info({:config_updated, gateway_url, streams, _cb, _cd, _to}, socket) do
    enabled =
      streams
      |> Enum.filter(fn s ->
        case s do
          %{enabled: en} -> en != false
          _ -> true
        end
      end)

    PageStore.put(:gateway_url, gateway_url)
    PageStore.put(:streams, streams)
    PageStore.put(:stream_list, enabled)

    {:noreply,
     socket
     |> assign(:gateway_url, gateway_url)
     |> assign(:stream_list, enabled)
     |> put_flash(:info, "监控配置已实时同步更新")}
  end

  @impl true
  def handle_info({:zone_updated, stream_id, zone_str}, socket) do
    updated_streams =
      Enum.map(socket.assigns.stream_list, fn s ->
        s_id =
          Map.get(s, :stream_id) || Map.get(s, "stream_id") || Map.get(s, :id) || Map.get(s, "id")

        if to_string(s_id) == to_string(stream_id) do
          case s do
            %Web.Orm.Entity.Stream{} -> %{s | zone_config: zone_str}
            map when is_map(map) -> Map.put(map, :zone_config, zone_str)
          end
        else
          s
        end
      end)

    PageStore.put(:stream_list, updated_streams)
    {:noreply, assign(socket, :stream_list, updated_streams)}
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}
end
