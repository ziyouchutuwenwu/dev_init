defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Web.PubSub, "config_updated")
    end

    gateway_url = Settings.get_gateway_url()
    alert_callback_url = Settings.get_alert_callback_url()
    alert_cooldown_sec = Settings.get_alert_cooldown_sec()
    alert_timeout_sec = Settings.get_alert_timeout_sec()
    streams = Streams.list_enabled_streams()
    config_streams = Streams.list_streams()

    {:ok,
     assign(socket,
       page_title: "视觉检测",
       gateway_url: gateway_url,
       alert_callback_url: alert_callback_url,
       alert_cooldown_sec: alert_cooldown_sec,
       alert_timeout_sec: alert_timeout_sec,
       stream_list: streams,
       config_stream_list: config_streams
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:config_updated, gateway_url, streams, alert_callback_url, alert_cooldown_sec, alert_timeout_sec}, socket) do
    {:noreply,
     assign(socket,
       gateway_url: gateway_url,
       alert_callback_url: alert_callback_url,
       alert_cooldown_sec: alert_cooldown_sec,
       alert_timeout_sec: alert_timeout_sec,
       stream_list: Enum.filter(streams, &(&1.enabled != false)),
       config_stream_list: streams
     )}
  end

  def handle_info({:config_updated, gateway_url, streams, alert_callback_url}, socket) do
    {:noreply,
     assign(socket,
       gateway_url: gateway_url,
       alert_callback_url: alert_callback_url,
       stream_list: Enum.filter(streams, &(&1.enabled != false)),
       config_stream_list: streams
     )}
  end

  def handle_info({:config_updated, gateway_url, streams}, socket) do
    {:noreply,
     assign(socket,
       gateway_url: gateway_url,
       stream_list: Enum.filter(streams, &(&1.enabled != false)),
       config_stream_list: streams
     )}
  end

  def handle_info(_other, socket) do
    {:noreply, socket}
  end
end
