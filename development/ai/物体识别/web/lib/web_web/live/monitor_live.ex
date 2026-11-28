defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Web.PubSub, "alerts")
    end

    socket =
      socket
      |> assign(:page_title, "视觉检测 - AI监控")
      |> assign(:active_tab, :monitor)
      |> assign(:gateway_url, Settings.get_gateway_url() || "")
      |> assign(:selected_classes, Settings.get_selected_classes() || [])
      |> assign(:stream_list, Streams.list_streams())
      |> assign(:connected_streams, MapSet.new())
      |> assign(:flash_timer, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("stream_connected_state", %{"stream_id" => stream_id, "connected" => true}, socket) do
    {:noreply, assign(socket, :connected_streams, MapSet.put(socket.assigns.connected_streams, stream_id))}
  end

  def handle_event("stream_connected_state", %{"stream_id" => stream_id, "connected" => false}, socket) do
    {:noreply, assign(socket, :connected_streams, MapSet.delete(socket.assigns.connected_streams, stream_id))}
  end

  @impl true
  def handle_info({:alert, %{stream_id: stream_id, alert_summary: summary} = alert_data}, socket) do
    stream = Enum.find(socket.assigns.stream_list, &(&1.stream_id == stream_id))
    is_connected = MapSet.member?(socket.assigns.connected_streams, stream_id)
    is_enabled = is_nil(stream) or stream.enabled

    if is_connected and is_enabled do
      model_id = alert_data[:model] || (stream && stream.model)

      if is_nil(model_id) or String.trim(to_string(model_id)) == "" do
        require Logger
        Logger.error("[monitor_live] 严重错误: 通道 [#{stream_id}] 缺失 model 配置，未展示告警")
        {:noreply, socket}
      else
        model_name =
          case Web.ModelLoader.get_model(model_id) do
            %{name: name} when is_binary(name) and name != "" -> name
            _ ->
              require Logger
              Logger.error("[monitor_live] 通道 [#{stream_id}] 未知模型 [#{model_id}]")
              to_string(model_id)
          end

        msg = "【通道 #{stream_id} #{model_name}】: #{summary}"
        if timer = socket.assigns[:flash_timer] do
          Process.cancel_timer(timer)
        end
        timer = Process.send_after(self(), :clear_flash, 5000)
        {:noreply, socket |> assign(:flash_timer, timer) |> put_flash(:error, msg)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, socket |> assign(:flash_timer, nil) |> clear_flash()}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
