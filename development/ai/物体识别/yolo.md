# yolo

## 说明

python 实现功能

elixir 展示

## 准备

go2rtc

## 代码

### python

依赖库

```sh
ultralytics
websockets
```

ws.py

```python
import json
import threading
import time
from websocket import WebSocketApp, WebSocketConnectionClosedException

from log import get_logger

log = get_logger("ws")


class WebSocketClient:
    """WebSocket 客户端，独立线程运行，断线自动重连"""

    def __init__(self, url: str) -> None:
        self.url = url
        self._ws: WebSocketApp | None = None
        self._thread: threading.Thread | None = None
        self._running = False
        self._connected = False

    def start(self) -> None:
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True, name="ws-thread")
        self._thread.start()

    def stop(self) -> None:
        self._running = False
        if self._ws:
            self._ws.close()

    @property
    def connected(self) -> bool:
        return self._connected

    def send(self, data: dict) -> None:
        if not self._ws:
            return
        try:
            msg = json.dumps(data, ensure_ascii=False)
            self._ws.send(msg)
        except WebSocketConnectionClosedException:
            log.debug("WebSocket 连接已关闭，消息丢弃")
        except Exception as e:
            log.error(f"发送消息失败: {e}")

    def _run(self) -> None:
        while self._running:
            try:
                self._ws = WebSocketApp(
                    self.url,
                    on_open=self._on_open,
                    on_close=self._on_close,
                    on_error=self._on_error,
                    on_message=self._on_message,
                )
                self._ws.run_forever()
            except Exception as e:
                log.error(f"WebSocket 异常: {e}")

            if self._running:
                log.info("3 秒后重连...")
                time.sleep(3)

    def _on_open(self, ws: WebSocketApp) -> None:
        self._connected = True
        log.info(f"WebSocket 已连接: {self.url}")

    def _on_close(
        self, ws: WebSocketApp, close_status_code: int, close_msg: str
    ) -> None:
        self._connected = False
        if close_status_code is not None:
            log.info(f"WebSocket 已断开: {close_status_code} {close_msg}")

    def _on_error(self, ws: WebSocketApp, error: Exception) -> None:
        log.debug(f"WebSocket 错误: {error}")

    def _on_message(self, ws: WebSocketApp, message: str) -> None:
        log.debug(f"收到消息: {message}")
```

detector.py

```python
import contextlib
import os
import sys
import time
from pathlib import Path

from ultralytics import YOLO
from ultralytics.engine.predictor import BasePredictor
from log import get_logger
from ws import WebSocketClient

log = get_logger("detector")


@contextlib.contextmanager
def suppress_stderr():
    original_stderr_fd = sys.stderr.fileno()
    saved_stderr_fd = os.dup(original_stderr_fd)
    devnull = os.open(os.devnull, os.O_WRONLY)
    os.dup2(devnull, original_stderr_fd)
    os.close(devnull)
    try:
        yield
    finally:
        os.dup2(saved_stderr_fd, original_stderr_fd)
        os.close(saved_stderr_fd)


class Detector:
    def __init__(
        self,
        ws_client: WebSocketClient | None = None,
        stream_url: str = "",
        model_path: str = "models/yolo11n.pt",
    ) -> None:
        self.ws_client = ws_client
        self.stream_url = stream_url
        self.model = YOLO(str(model_path))
        self._register_callbacks()

    def predict(self, source: str, **kwargs) -> None:
        while True:
            try:
                with suppress_stderr():
                    for _ in self.model.predict(source=source, stream=True, **kwargs):
                        pass
            except KeyboardInterrupt:
                raise
            except Exception:
                pass

            log.info("3 秒后重试...")
            time.sleep(3)

    def _register_callbacks(self) -> None:
        self.model.add_callback(
            "on_predict_postprocess_end", self._on_predict_postprocess_end
        )
        self.model.add_callback("on_predict_batch_end", self._on_predict_batch_end)

    def _on_predict_postprocess_end(self, predictor: BasePredictor) -> None:
        self._handle_detection(predictor)

    def _on_predict_batch_end(self, predictor: BasePredictor) -> None:
        pass
        # self._handle_detection(predictor)

    def _handle_detection(self, predictor: BasePredictor) -> None:
        if not self.ws_client:
            return

        fps = (
            predictor.dataset.fps[0]
            if isinstance(predictor.dataset.fps, (list, tuple))
            else getattr(predictor.dataset, "fps", 0)
        )

        results = predictor.results
        if not results:
            return

        detections: list[dict] = []
        for result in results:
            if result.boxes is None:
                continue

            boxes = (
                result.boxes.xyxy.cpu().numpy().tolist()
                if result.boxes.xyxy is not None
                else []
            )
            classes = (
                result.boxes.cls.cpu().numpy().tolist()
                if result.boxes.cls is not None
                else []
            )
            confs = (
                result.boxes.conf.cpu().numpy().tolist()
                if result.boxes.conf is not None
                else []
            )
            names = [result.names[int(c)] for c in classes]

            for box, cls_name, conf in zip(boxes, names, confs):
                detections.append(
                    {
                        "x1": round(box[0], 2),
                        "y1": round(box[1], 2),
                        "x2": round(box[2], 2),
                        "y2": round(box[3], 2),
                        "class": cls_name,
                        "confidence": round(conf, 4),
                    }
                )

        payload = {
            "stream": self.stream_url,
            "fps": fps,
            "detections": detections,
        }

        self.ws_client.send(payload)
```

log.py

```python
import logging
import sys


def setup(level: int = logging.INFO) -> None:
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)

    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.StreamHandler(sys.stdout),
        ],
    )

    logging.getLogger("ultralytics").setLevel(logging.WARNING)
    logging.getLogger("websocket").setLevel(logging.CRITICAL)
    logging.getLogger("urllib3").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
```

main.py

```python
from detector import Detector
from log import get_logger, setup as log_setup
from ws import WebSocketClient

log = get_logger("main")


def main() -> None:
    stream_url = "http://127.0.0.1:1984/api/stream.mjpeg?src=camera_02"
    ws_url = "ws://localhost:4000/ws/detect"

    log_setup()

    log.info(f"启动检测器, 流地址: {stream_url}")

    ws_client = WebSocketClient(ws_url)
    ws_client.start()

    detector = Detector(ws_client=ws_client, stream_url=stream_url)

    try:
        detector.predict(source=stream_url)
    except KeyboardInterrupt:
        log.info("收到中断信号，正在退出...")
    except Exception as e:
        log.exception(f"运行异常: {e}")
    finally:
        ws_client.stop()


if __name__ == "__main__":
    main()
```

### elixir

router.ex

```elixir
defmodule WebDemoWeb.Router do
  use WebDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/live", StreamLive
  end
end
```

endpoint.ex

```elixir
socket "/live", Phoenix.LiveView.Socket,
  websocket: [connect_info: [session: @session_options]],
  longpoll: [connect_info: [session: @session_options]]

socket "/ws", WebDemoWeb.BridgeSocket,
  websocket: [
    path: "/detect",
    connect_info: [:x_headers, :uri, :peer_data, session: @session_options]
  ],
  longpoll: false
```

bridge_socket.ex

```elixir
defmodule WebDemoWeb.BridgeSocket do
  @behaviour WebSock
  require Logger

  @pubsub WebDemo.PubSub
  @topic "detection"

  def connect(state) do
    Logger.debug("on connect #{inspect(self())}")
    {:ok, state}
  end

  def init(state) do
    Logger.debug("on init #{inspect(state)} #{inspect(self())}")
    connect(state)
  end

  def handle_in({text, _opts}, state) do
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:raw_detection, text})
    {:ok, state}
  end

  def handle_info(_AAA, state) do
    Logger.debug("on handle_info state #{inspect(state)} #{inspect(self())}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.debug("on terminate reason #{inspect(reason)}")
    :ok
  end
end
```

stream_live.ex

```elixir
defmodule WebDemoWeb.StreamLive do
  use WebDemoWeb, :live_view
  require Logger

  embed_templates "live/*"

  @pubsub WebDemo.PubSub
  @topic "detection"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(@pubsub, @topic)
    end

    stream_url_list = [
      "http://127.0.0.1:1984/stream.html?src=camera_02"
    ]

    {:ok,
     assign(socket,
       stream_url_list: stream_url_list,
       connected: false,
       count: 0,
       fps: 0.0,
       object_count: 0
     )}
  end

  def handle_info({:raw_detection, text}, socket) do
    {detections, fps, count} =
      case Jason.decode(text) do
        {:ok, data} ->
          dets = normalize_detections(data)
          raw_fps = data["fps"] || data["frame_rate"] || data["framerate"] || data["FPS"]

          fps_val =
            case raw_fps do
              n when is_number(n) ->
                n / 1

              s when is_binary(s) ->
                case Float.parse(s) do
                  {f, _} ->
                    f

                  :error ->
                    case Integer.parse(s) do
                      {i, _} -> i / 1
                      :error -> socket.assigns.fps
                    end
                end

              _ ->
                socket.assigns.fps
            end

          cnt = socket.assigns.count + 1
          {dets, fps_val, cnt}

        {:error, reason} ->
          Logger.error("Failed to decode JSON: #{inspect(reason)}, text: #{text}")
          {[], socket.assigns.fps, socket.assigns.count}
      end

    {:noreply,
     socket
     |> assign(:connected, true)
     |> assign(:object_count, length(detections))
     |> assign(:count, count)
     |> assign(:fps, fps)
     |> push_event("detections", %{detections: detections})}
  end

  defp normalize_detections(data) do
    items =
      cond do
        is_list(data) -> data
        is_map(data) and Map.has_key?(data, "detections") -> data["detections"]
        is_map(data) and Map.has_key?(data, "objects") -> data["objects"]
        is_map(data) and Map.has_key?(data, "results") -> data["results"]
        is_map(data) and Map.has_key?(data, "boxes") -> data["boxes"]
        is_map(data) and Map.has_key?(data, "predictions") -> data["predictions"]
        true -> [data]
      end

    if is_list(items) do
      Enum.map(items, fn det -> to_detection(det, data) end) |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp to_detection(det, data) when is_map(det) do
    type =
      det["type"] || det["label"] || det["class"] || det["name"] || det["category"] ||
        det["class_name"] || "object"

    bbox = det["bbox"] || det["box"] || det["bounding_box"] || det["rect"]

    to_f = fn
      v when is_number(v) ->
        v / 1

      v when is_binary(v) ->
        case Float.parse(v) do
          {f, _} -> f
          :error -> 0.0
        end

      _ ->
        0.0
    end

    {raw_x, raw_y, raw_w_or_x2, raw_h_or_y2} =
      cond do
        is_list(bbox) and length(bbox) == 4 ->
          [n1, n2, n3, n4] =
            Enum.map(bbox, fn n -> if is_number(n), do: n / 1, else: String.to_float(n) end)

          {n1, n2, n3, n4}

        det["x1"] && det["y1"] && det["x2"] && det["y2"] ->
          {to_f.(det["x1"]), to_f.(det["y1"]), to_f.(det["x2"]), to_f.(det["y2"])}

        det["xmin"] && det["ymin"] && det["xmax"] && det["ymax"] ->
          {to_f.(det["xmin"]), to_f.(det["ymin"]), to_f.(det["xmax"]), to_f.(det["ymax"])}

        det["x"] && det["y"] && (det["width"] || det["w"]) && (det["height"] || det["h"]) ->
          x_val = to_f.(det["x"])
          y_val = to_f.(det["y"])
          w_val = to_f.(det["width"] || det["w"])
          h_val = to_f.(det["height"] || det["h"])
          {x_val, y_val, w_val, h_val}

        true ->
          {nil, nil, nil, nil}
      end

    if raw_x && raw_y && raw_w_or_x2 && raw_h_or_y2 do
      root_img_w =
        if is_map(data),
          do:
            data["img_width"] || data["image_width"] || data["width_ref"] || data["width"] ||
              data["frame_width"],
          else: nil

      root_img_h =
        if is_map(data),
          do:
            data["img_height"] || data["image_height"] || data["height_ref"] || data["height"] ||
              data["frame_height"],
          else: nil

      det_img_w = det["img_width"] || det["image_width"] || det["width_ref"]
      det_img_h = det["img_height"] || det["image_height"] || det["height_ref"]

      img_w =
        cond do
          det_img_w -> to_f.(det_img_w)
          root_img_w -> to_f.(root_img_w)
          raw_w_or_x2 > 1280.0 or raw_h_or_y2 > 720.0 -> 1920.0
          raw_w_or_x2 > 640.0 or raw_h_or_y2 > 480.0 -> 1280.0
          true -> 640.0
        end

      img_h =
        cond do
          det_img_h -> to_f.(det_img_h)
          root_img_h -> to_f.(root_img_h)
          raw_w_or_x2 > 1280.0 or raw_h_or_y2 > 720.0 -> 1080.0
          raw_w_or_x2 > 640.0 or raw_h_or_y2 > 480.0 -> 720.0
          true -> 480.0
        end

      {x, width} =
        if raw_w_or_x2 > 1.0 or raw_x > 1.0 do
          w_ref = if is_number(img_w) and img_w > 1.0, do: img_w, else: 640.0
          nx = raw_x / w_ref

          nw =
            if raw_w_or_x2 < raw_x, do: raw_w_or_x2 / w_ref, else: (raw_w_or_x2 - raw_x) / w_ref

          {nx, nw}
        else
          nx = raw_x
          nw = if raw_w_or_x2 < raw_x, do: raw_w_or_x2, else: raw_w_or_x2 - raw_x
          {nx, nw}
        end

      {y, height} =
        if raw_h_or_y2 > 1.0 or raw_y > 1.0 do
          h_ref = if is_number(img_h) and img_h > 1.0, do: img_h, else: 480.0
          ny = raw_y / h_ref

          nh =
            if raw_h_or_y2 < raw_y, do: raw_h_or_y2 / h_ref, else: (raw_h_or_y2 - raw_y) / h_ref

          {ny, nh}
        else
          ny = raw_y
          nh = if raw_h_or_y2 < raw_y, do: raw_h_or_y2, else: raw_h_or_y2 - raw_y
          {ny, nh}
        end

      cl = fn v -> max(0.0, min(v, 1.0)) end

      %{
        type: to_string(type),
        x: cl.(x),
        y: cl.(y),
        width: cl.(width),
        height: cl.(height)
      }
    else
      nil
    end
  end
end
```

yolo_live.html.heex

```html
<Layouts.app flash={@flash} current_scope={%{}}>
  <div class="flex flex-col items-center bg-gray-950 p-4 pb-10 gap-4">
    <div class="flex items-center justify-between w-full max-w-5xl">
      <h1 class="text-2xl font-bold text-white">实时识别</h1>
      <div class="flex items-center gap-2 text-sm">
        <span class={[
          "px-2.5 py-1 rounded-full font-medium",
          if(@connected,
            do: "bg-emerald-500/20 text-emerald-300",
            else: "bg-rose-500/20 text-rose-300"
          )
        ]}>
          <span class={[
            "inline-block w-2 h-2 rounded-full mr-1.5",
            if(@connected, do: "bg-emerald-400", else: "bg-rose-400")
          ]}>
          </span>
          {if(@connected, do: "检测中", else: "等待检测器")}
        </span>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 w-full max-w-5xl">
      <div
        :for={{url, index} <- Enum.with_index(@stream_url_list)}
        class="relative rounded-xl overflow-hidden shadow-2xl border border-gray-700 bg-black"
      >
        <div
          id={"yolo-player-#{index}"}
          class="relative w-full aspect-video bg-black overflow-hidden"
        >
          <iframe
            src={url}
            class="absolute inset-0 w-full h-full border-0 pointer-events-none"
            allow="autoplay; fullscreen; picture-in-picture"
          >
          </iframe>
          <%= if index == 0 do %>
            <canvas
              id="yolo-overlay"
              phx-hook=".Player"
              phx-update="ignore"
              class="absolute inset-0 w-full h-full pointer-events-none z-10"
            >
            </canvas>
          <% end %>
        </div>
      </div>
    </div>

    <div class="flex flex-wrap gap-3 text-sm text-gray-200 w-full max-w-5xl">
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-bolt" class="w-4 h-4 text-amber-400" />
        <span class="text-gray-400">帧率</span>
        <span class="font-semibold text-white tabular-nums">{Float.round(@fps, 1)} FPS</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-squares-2x2" class="w-4 h-4 text-emerald-400" />
        <span class="text-gray-400">目标数</span>
        <span class="font-semibold text-white tabular-nums">{@object_count}</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-eye" class="w-4 h-4 text-sky-400" />
        <span class="text-gray-400">检测帧数</span>
        <span class="font-semibold text-white tabular-nums">{@count}</span>
      </div>
    </div>
  </div>

  <script :type={Phoenix.LiveView.ColocatedHook} name=".Player">
    export default {
      mounted() {
        this.handleEvent("detections", (payload) => {
          if (payload && payload.detections) {
            this.renderBoxes(payload.detections)
          }
        })
      },

      renderBoxes(detections) {
        const canvas = document.getElementById("yolo-overlay")
        if (!canvas) return
        const ctx = canvas.getContext("2d")
        if (canvas.clientWidth === 0 || canvas.clientHeight === 0) return
        if (canvas.width !== canvas.clientWidth || canvas.height !== canvas.clientHeight) {
          canvas.width = canvas.clientWidth
          canvas.height = canvas.clientHeight
        }
        ctx.clearRect(0, 0, canvas.width, canvas.height)

        const colors = {
          person: "#4ade80",
          car: "#60a5fa",
          truck: "#60a5fa",
          bicycle: "#facc15",
          motorcycle: "#facc15",
          bus: "#60a5fa",
          dog: "#f472b6",
          cat: "#f472b6",
          bird: "#c084fc",
          "traffic light": "#fb923c",
          "fire hydrant": "#f87171",
          "stop sign": "#f87171"
        }

        detections.forEach((det) => {
          const x = (det.x !== undefined ? det.x : 0) * canvas.width
          const y = (det.y !== undefined ? det.y : 0) * canvas.height
          const w = (det.width !== undefined ? det.width : 0) * canvas.width
          const h = (det.height !== undefined ? det.height : 0) * canvas.height

          const type = det.type || "object"
          const color = colors[type] || "#f87171"

          ctx.strokeStyle = color
          ctx.lineWidth = 3
          ctx.strokeRect(x, y, w, h)

          ctx.fillStyle = color
          ctx.fillRect(x, Math.max(0, y - 22), Math.max(70, type.length * 9), 22)

          ctx.fillStyle = "#ffffff"
          ctx.font = "bold 12px sans-serif"
          ctx.fillText(type, x + 6, Math.max(15, y - 6))
        })
      }
    }
  </script>
</Layouts.app>
```
