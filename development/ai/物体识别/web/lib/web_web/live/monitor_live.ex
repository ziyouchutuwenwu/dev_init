defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams
  alias Web.DataSync

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Web.PubSub, "alerts")
    end

    socket =
      socket
      |> assign(:page_title, "视觉检测 - 工业检测AI监控")
      |> assign(:active_tab, :monitor)
      |> assign(:gateway_url, Settings.get_gateway_url() || "")
      |> assign(:selected_classes, Settings.get_selected_classes() || [])
      |> assign(:stream_list, Streams.list_streams())
      |> assign(:connected_streams, MapSet.new())

    {:ok, socket}
  end

  @impl true
  def handle_event("stream_connected_state", %{"stream_id" => stream_id, "connected" => true}, socket) do
    {:noreply, assign(socket, :connected_streams, MapSet.put(socket.assigns.connected_streams, stream_id))}
  end

  def handle_event("stream_connected_state", %{"stream_id" => stream_id, "connected" => false}, socket) do
    {:noreply, assign(socket, :connected_streams, MapSet.delete(socket.assigns.connected_streams, stream_id))}
  end

  def handle_event("toggle_stream_enabled", %{"stream_id" => stream_id}, socket) do
    case Streams.get_stream_by_stream_id(stream_id) do
      nil ->
        {:noreply, socket}

      stream ->
        new_enabled = !stream.enabled

        case Streams.update_stream_enabled(stream_id, new_enabled) do
          {:ok, _updated} ->
            streams = Streams.list_streams()
            gateway_url = socket.assigns.gateway_url

            if is_binary(gateway_url) and String.trim(gateway_url) != "" do
              Task.start(fn ->
                DataSync.sync_to_gateway(
                  gateway_url,
                  streams,
                  Settings.get_alert_callback_url() || "",
                  Settings.get_alert_cooldown_sec() || "1",
                  Settings.get_alert_timeout_sec() || "3"
                )
              end)
            end

            {:noreply, assign(socket, :stream_list, streams)}

          {:error, _reason} ->
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_info({:industrial_alert, %{stream_id: stream_id, alert_summary: summary}}, socket) do
    stream = Enum.find(socket.assigns.stream_list, &(&1.stream_id == stream_id))
    is_connected = MapSet.member?(socket.assigns.connected_streams, stream_id)
    is_enabled = stream && stream.enabled

    if is_connected and is_enabled do
      msg = "【通道 #{stream_id} 工业告警】: #{summary}"
      {:noreply, put_flash(socket, :error, msg)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
