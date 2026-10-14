defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams
  alias Web.DataSync

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "视觉检测")
      |> assign(:active_tab, :monitor)
      |> assign(:gateway_url, Settings.get_gateway_url() || "")
      |> assign(:stream_list, Streams.list_streams())

    {:ok, socket}
  end

  @impl true
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
  def handle_info(_msg, socket), do: {:noreply, socket}
end
