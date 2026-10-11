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

    live "/", MonitorLive, :home
    live "/config", MonitorLive, :config
  end

  scope "/api", WebWeb do
    pipe_through :api

    post "/alert", AlertController, :create

    post "/config/save-local", ConfigController, :save_local
    post "/config/sync-to-hardware", ConfigController, :sync_to_hardware

    get "/zone/:stream_id", ConfigController, :get_zone
    post "/zone/:stream_id", ConfigController, :save_zone
  end
end
