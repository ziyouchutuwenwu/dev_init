defmodule WebWeb.MonitorLive do
  use WebWeb, :live_view

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "视觉检测")
      |> assign(:active_tab, :monitor)
      |> assign(:gateway_url, Settings.get_gateway_url() || "")
      |> assign(:stream_list, Streams.list_enabled_streams())

    {:ok, socket}
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}
end
