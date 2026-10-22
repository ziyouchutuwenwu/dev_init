defmodule WebWeb.AlertController do
  use WebWeb, :controller
  require Logger

  alias Web.Orm.Query.Settings
  alias Web.Orm.Query.Streams

  def create(conn, params) do
    # 打印接口请求参数（Method, URL, Query, Body JSON）便于直观调试
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

    # 1. 勾选了检测：通道必须开启检测功能
    if stream && !stream.enabled do
      conn
      |> put_status(:ok)
      |> json(%{status: "ignored", reason: "stream detection disabled"})
    else
      # 2. 识别出来的目标校验 (垂直模型与通用检测直接由底层驱动，默认不过滤)
      stream_model = (stream && stream.model) || params["model"] || "industry"
      selected_classes = Settings.get_selected_classes() || []
      raw_detections = params["detections"] || []

      valid_detections =
        if stream_model != "industry" or selected_classes == [] or not is_list(raw_detections) do
          raw_detections
        else
          Enum.filter(raw_detections, fn d ->
            label = to_string(d["label"] || d["class"] || "")
            alert_type = to_string(d["alert_type"] || "")
            rule_id = to_string(d["rule_id"] || (is_map(d["extra"]) && d["extra"]["rule_id"]) || "")
            rule_name = to_string(d["rule_name"] || (is_map(d["extra"]) && d["extra"]["rule_name"]) || "")

            Enum.any?(selected_classes, fn sc ->
              sc = to_string(sc)

              label == sc or
                alert_type == sc or
                String.contains?(alert_type, sc) or
                rule_id == sc or
                rule_name == sc or
                (sc in ["person", "人员目标"] and label in ["person", "0", "人员", "人员目标"]) or
                (sc in ["no-hardhat", "hardhat", "未戴安全帽"] and (String.contains?(alert_type, "安全帽") or rule_id == "rule_hardhat" or label in ["hardhat", "helmet"])) or
                (sc in ["no-safety-vest", "safety-vest", "未穿反光衣"] and (String.contains?(alert_type, "反光衣") or rule_id == "rule_safety_vest" or label in ["safety-vest", "vest"])) or
                (sc in ["forklift", "叉车"] and (label == "forklift" or String.contains?(alert_type, "叉车") or rule_id == "rule_forklift_collision")) or
                (sc in ["smoking", "抽烟"] and (label in ["smoking", "cigarette"] or String.contains?(alert_type, "抽烟") or rule_id == "rule_smoking_phone")) or
                (sc in ["phone-call", "打电话"] and (label in ["phone-call", "cellphone"] or String.contains?(alert_type, "电话") or rule_id == "rule_smoking_phone")) or
                (sc in ["fire", "明火"] and (label == "fire" or String.contains?(alert_type, "火") or rule_id == "rule_fire_smoke")) or
                (sc in ["smoke", "烟雾"] and (label == "smoke" or String.contains?(alert_type, "烟") or rule_id == "rule_fire_smoke")) or
                (sc in ["fall-down", "倒地"] and (label == "fall-down" or String.contains?(alert_type, "倒地") or rule_id == "rule_falldown_sleep")) or
                (sc in ["sleeping", "睡岗"] and (label == "sleeping" or String.contains?(alert_type, "睡岗") or rule_id == "rule_falldown_sleep")) or
                (sc in ["license_plate", "车牌", "车牌识别"] and (label in ["license_plate", "plate"] or rule_id == "rule_license_plate" or (is_map(d["extra"]) && is_binary(d["extra"]["plate_text"]))))
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
            is_binary(params["alert_name"]) and params["alert_name"] != "" and params["alert_name"] != "检测到目标" ->
              params["alert_name"]

            is_list(valid_detections) and count > 0 ->
              valid_detections
              |> Enum.map(fn d ->
                (is_map(d["extra"]) && (d["extra"]["plate_text"] || d["extra"]["rule_name"])) ||
                  d["name"] ||
                  d["label"] ||
                  d["alert_type"] ||
                  "目标"
              end)
              |> Enum.uniq()
              |> Enum.join(", ")

            true ->
              params["alert_name"] || "常规目标"
          end

        model_name = params["model_name"] || "工业检测"
        Logger.info("[alert_controller] 收到通道 [#{stream_id}] #{model_name}告警: 【#{alert_summary}】 (目标数: #{count})")

        Phoenix.PubSub.broadcast(Web.PubSub, "alerts", {
          :industrial_alert,
          %{
            event_id: params["event_id"],
            stream_id: stream_id,
            model: params["model"],
            model_name: model_name,
            alert_type: params["alert_type"],
            alert_name: params["alert_name"] || alert_summary,
            alert_level: params["alert_level"] || "info",
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
