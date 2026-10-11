defmodule WebWeb.AlertController do
  use WebWeb, :controller
  require Logger

  def create(conn, params) do
    stream_id = params["stream_id"] || "unknown"
    detections = params["detections"] || []

    Logger.info(
      "[alert_controller] 收到来自通道 #{stream_id} 的告警事件通知，当前检测目标数: #{length(detections)}"
    )

    conn
    |> put_status(:ok)
    |> json(%{status: "ok", received: true})
  end
end
