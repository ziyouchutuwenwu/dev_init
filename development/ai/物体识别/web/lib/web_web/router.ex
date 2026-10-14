defmodule WebWeb.Router do
  use WebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebWeb do
    pipe_through :browser

    live_session :default do
      live "/", MonitorLive, :index
      live "/config", ConfigLive, :index
    end
  end

  scope "/api", WebWeb do
    pipe_through :api

    post "/alert", AlertController, :create

    post "/config/save-local", ConfigSyncController, :save_local
    post "/config/sync-to-hardware", ConfigSyncController, :sync_to_hardware

    get "/zone/:stream_id", ConfigSyncController, :get_zone
    post "/zone/:stream_id", ConfigSyncController, :save_zone
    post "/stream/:stream_id/toggle", ConfigSyncController, :toggle_stream
  end
end
