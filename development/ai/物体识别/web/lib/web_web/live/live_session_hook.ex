defmodule WebWeb.LiveSessionHook do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Web.PubSub, "config_updated")
    end

    socket =
      socket
      |> assign(:gateway_url, Web.PageStore.get(:gateway_url, ""))
      |> assign(:alert_callback_url, Web.PageStore.get(:alert_callback_url, ""))
      |> assign(:alert_cooldown_sec, Web.PageStore.get(:alert_cooldown_sec, "1"))
      |> assign(:alert_timeout_sec, Web.PageStore.get(:alert_timeout_sec, "3"))
      |> assign(:all_streams, Web.PageStore.get(:streams, []))
      |> assign(:stream_list, Web.PageStore.get(:stream_list, []))

    {:cont, socket}
  end
end
