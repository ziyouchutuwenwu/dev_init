defmodule WebWeb.AlertController do
  use WebWeb, :controller
  require Logger

  alias Web.Orm.Query.Streams

  def create(conn, params) do
    method = conn.method
    req_url = Plug.Conn.request_url(conn)
    query_str = conn.query_string
    json_str =
      case Jason.encode(params, pretty: true) do
        {:ok, encoded} -> encoded
        _ -> inspect(params, pretty: true)
      end

    Logger.info("""
    ==================== [AI 告警回调请求详情] ====================
    Method : #{method}
    URL    : #{req_url}#{if query_str != "", do: "\nQuery  : #{query_str}", else: ""}
    JSON   :
    #{json_str}
    ================================================================
    """)

    stream_id = params["stream_id"] || "unknown"
    stream = Streams.get_stream_by_stream_id(stream_id)

    if stream && !stream.enabled do
      conn
      |> put_status(:ok)
      |> json(%{status: "ignored", reason: "stream detection disabled"})
    else
      stream_model = (stream && stream.model) || params["model_id"] || params["model"]

      if is_nil(stream_model) or String.trim(to_string(stream_model)) == "" do
        Logger.error("[alert_controller] 严重错误: 通道 [#{stream_id}] 缺失 model 配置且严禁默认兜底，拒绝处理！")

        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", reason: "missing model configuration"})
      else
        selected_classes =
          case stream do
            %{zone_config: zc} when is_binary(zc) and zc != "" ->
              case Jason.decode(zc) do
                {:ok, %{"target_classes" => tc}} when is_list(tc) -> tc
                _ -> []
              end
            _ ->
              []
          end
        raw_detections = params["detections"] || []

        label_map = Web.ModelLoader.label_display_map()

        valid_detections =
          if selected_classes == [] or not is_list(raw_detections) do
            raw_detections
          else
            Enum.filter(raw_detections, fn d ->
              label = to_string(d["label"] || d["class"] || "")
              alert_type = to_string(d["alert_type"] || "")
              rule_id = to_string(d["rule_id"] || (is_map(d["extra"]) && d["extra"]["rule_id"]) || "")

              l_label = String.downcase(label)
              l_alert_type = String.downcase(alert_type)
              l_rule_id = String.downcase(rule_id)

              has_text =
                (is_binary(d["text"]) and d["text"] != "") or
                  (is_binary(d["plate_text"]) and d["plate_text"] != "") or
                  (is_map(d["extra"]) and is_binary(d["extra"]["plate_text"]))

              Enum.any?(selected_classes, fn sc ->
                sc_str = to_string(sc)
                l_sc = String.downcase(sc_str)
                norm_sc = String.replace(l_sc, "-", "_")
                norm_label = String.replace(l_label, "-", "_")
                norm_alert = String.replace(l_alert_type, "-", "_")
                disp_name = String.downcase(to_string(label_map[sc_str] || label_map[l_sc] || ""))

                norm_label == norm_sc or
                  l_label == l_sc or
                  l_alert_type == l_sc or
                  norm_alert == norm_sc or
                  (disp_name != "" and (l_label == disp_name or l_alert_type == disp_name or String.contains?(l_alert_type, disp_name))) or
                  (l_sc != "" and String.contains?(l_alert_type, l_sc)) or
                  l_rule_id == l_sc or
                  (has_text and norm_sc in ["license_plate", "plate", "lprnet"])
              end)
            end)
          end

      count = if is_list(valid_detections), do: length(valid_detections), else: 0

      if count == 0 and is_list(raw_detections) and length(raw_detections) > 0 do
        conn
        |> put_status(:ok)
        |> json(%{status: "ignored", reason: "no matched targets"})
      else
        alert_summary =
          cond do
            is_binary(params["alert"]) and params["alert"] != "" and params["alert"] != "检测到目标" ->
              params["alert"]

            is_binary(params["alert_name"]) and params["alert_name"] != "" and params["alert_name"] != "检测到目标" ->
              params["alert_name"]

            is_list(valid_detections) and count > 0 ->
              valid_detections
              |> Enum.map(fn d ->
                d["text"] ||
                  d["plate_text"] ||
                  (is_map(d["extra"]) && (d["extra"]["plate_text"] || d["extra"]["rule_name"])) ||
                  d["detail"] ||
                  d["name"] ||
                  d["label"] ||
                  d["alert_type"] ||
                  "目标"
              end)
              |> Enum.uniq()
              |> Enum.join(", ")

            true ->
              params["alert"] || params["alert_name"] || "常规目标"
          end

        alert_level =
          cond do
            is_binary(params["alert_level"]) and params["alert_level"] != "" ->
              params["alert_level"]

            String.contains?(alert_summary, ["预警", "未戴", "未穿", "缺陷", "火", "烟", "违规", "crash", "collision"]) ->
              "warning"

            true ->
              "info"
          end

        model_name =
          case Web.ModelLoader.get_model(stream_model) do
            %{name: name} when is_binary(name) and name != "" -> name
            _ -> stream_model
          end

        Logger.info("[alert_controller] 收到通道 [#{stream_id}] #{model_name}告警: 【#{alert_summary}】 (目标数: #{count})")

        Phoenix.PubSub.broadcast(Web.PubSub, "alerts", {
          :alert,
          %{
            event_id: params["event_id"] || "evt_#{stream_id}_#{params["timestamp"] || System.system_time(:millisecond)}",
            stream_id: stream_id,
            model: stream_model,
            model_name: model_name,
            alert_type: params["alert"] || params["alert_type"] || alert_summary,
            alert_name: params["alert"] || params["alert_name"] || alert_summary,
            alert_level: alert_level,
            count: count,
            alert_summary: alert_summary,
            detections: valid_detections,
            frame_info: params["frame_info"],
            timestamp: params["timestamp"] || System.system_time(:millisecond)
          }
        })

        conn
        |> put_status(:ok)
        |> json(%{status: "ok", received: true, alert_summary: alert_summary})
      end
    end
  end
end
end
