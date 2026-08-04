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
aiortc
ultralytics
websockets
websocket-client
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
import time
from typing import Any
from urllib.parse import parse_qs, urlparse
from ultralytics import YOLO
from log import get_logger
from transcode import FrameSource
from ws import WebSocketClient

log = get_logger("detector")

FRAME_TIMEOUT = 30
RECONNECT_DELAY = 3


class Detector:
    def __init__(
        self,
        ws_client: WebSocketClient,
        stream_url: str,
        stream_name: str | None = None,
        source_url: str | None = None,
        model_path: str = "models/yolo11n.pt",
        conf: float = 0.25,
    ) -> None:
        self.ws_client = ws_client
        self.stream_url = stream_url
        self.stream_name = stream_name or self._derive_name(stream_url)
        self.source_url = source_url or self._derive_source_url(stream_url)
        self.conf = conf

        self._model = YOLO(model_path)
        self._running = True
        self._source = FrameSource(self.stream_url)

        self._current_fps = 0.0
        self._frame_count = 0
        self._window_start = 0.0

    @staticmethod
    def _derive_name(stream_url: str) -> str:
        p = urlparse(stream_url)
        return parse_qs(p.query).get("src", ["stream"])[0]

    @staticmethod
    def _derive_source_url(stream_url: str) -> str:
        p = urlparse(stream_url)
        src = parse_qs(p.query).get("src", ["stream"])[0]
        scheme = "wss" if p.scheme == "https" else "ws"
        return f"{scheme}://{p.netloc}/api/ws?src={src}"

    def request_shutdown(self) -> None:
        self._running = False
        self._source.stop()

    def run(self) -> None:
        while self._running:
            try:
                self._stream_once()
            except Exception as e:
                if not self._running:
                    break
                log.warning(f"拉流中断: {e}")
            if not self._running:
                break
            log.info(f"{RECONNECT_DELAY}s 后重连...")
            time.sleep(RECONNECT_DELAY)

    def _stream_once(self) -> None:
        self._source.start()
        try:
            self._infer_loop()
        finally:
            self._source.stop()

    def _infer_loop(self) -> None:
        self._window_start = time.time()
        self._frame_count = 0

        while self._running:
            if not self._source.wait(timeout=FRAME_TIMEOUT):
                raise RuntimeError(f"{FRAME_TIMEOUT}s 内没有收到视频帧")
            self._source.clear()

            frame = self._source.latest()
            if frame is None:
                continue

            results = self._model.predict(frame, conf=self.conf, verbose=False)
            if results is None:
                continue

            self._frame_count += 1
            elapsed = time.time() - self._window_start
            if elapsed >= 1.0:
                self._current_fps = self._frame_count / elapsed
                self._frame_count = 0
                self._window_start = time.time()

            self._handle_detection(results)

    def _handle_detection(self, results: Any) -> None:
        if not self.ws_client:
            return

        detections: list[dict] = []
        for result in results:
            if result.boxes is None:
                continue

            boxes = result.boxes.xyxy.cpu().numpy().tolist() if result.boxes.xyxy is not None else []
            classes = result.boxes.cls.cpu().numpy().tolist() if result.boxes.cls is not None else []
            confs = result.boxes.conf.cpu().numpy().tolist() if result.boxes.conf is not None else []
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

        if not detections:
            return

        payload = {
            "stream": self.stream_name,
            "url": self.stream_url,
            "fps": round(self._current_fps, 2),
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

transcode.py

```python
import asyncio
import json
import threading
import time
from typing import Any
from urllib.parse import parse_qs, urlparse
import websockets
from aiortc import RTCPeerConnection, RTCIceCandidate, RTCSessionDescription
from log import get_logger

log = get_logger("transcode")


class FrameSource:
    def __init__(self, stream_url: str, reconnect_delay: int = 3) -> None:
        p = urlparse(stream_url)
        self._src = parse_qs(p.query).get("src", ["stream"])[0]
        self._host = p.netloc
        self._scheme = "wss" if p.scheme == "https" else "ws"
        self._reconnect_delay = reconnect_delay
        self._running = False
        self._latest: Any = None
        self._frame_ready = threading.Event()
        self._thread: threading.Thread | None = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._ws: Any = None
        self._pc: RTCPeerConnection | None = None

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._running = True
        self._thread = threading.Thread(target=self._run, daemon=True, name="framesrc")
        self._thread.start()

    def stop(self) -> None:
        self._running = False
        self._frame_ready.set()
        if self._loop is not None:
            if self._ws is not None:
                self._loop.call_soon_threadsafe(lambda: asyncio.ensure_future(self._ws.close()))
            if self._pc is not None:
                self._loop.call_soon_threadsafe(lambda: asyncio.ensure_future(self._pc.close()))

    def latest(self) -> Any:
        return self._latest

    def wait(self, timeout: float) -> bool:
        return self._frame_ready.wait(timeout)

    def clear(self) -> None:
        self._frame_ready.clear()

    def _run(self) -> None:
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        while self._running:
            try:
                self._loop.run_until_complete(self._run_webrtc())
            except Exception as e:
                if not self._running:
                    break
                log.warning(f"拉流中断: {e}")
            if not self._running:
                break
            time.sleep(self._reconnect_delay)

    async def _run_webrtc(self) -> None:
        pc = RTCPeerConnection()
        self._pc = pc
        ws_holder: dict[str, Any] = {}

        @pc.on("track")
        def on_track(track: Any) -> None:
            if track.kind == "video":
                log.info(f"收到 video track: {track}")
                self._loop.create_task(self._recv_webrtc(track))

        @pc.on("icecandidate")
        def on_ice(candidate: Any) -> None:
            ws = ws_holder.get("ws")
            if candidate and ws:
                self._loop.create_task(
                    ws.send(json.dumps({"type": "webrtc", "value": {"ice": candidate.to_json()}}))
                )

        url = f"{self._scheme}://{self._host}/api/ws?src={self._src}"
        log.info(f"连接 go2rtc WS: {url}")
        async with websockets.connect(url) as ws:
            ws_holder["ws"] = ws
            self._ws = ws

            pc.addTransceiver("video", direction="recvonly")
            offer = await pc.createOffer()
            await pc.setLocalDescription(offer)
            await ws.send(
                json.dumps({"type": "webrtc", "value": {"type": "offer", "sdp": pc.localDescription.sdp}})
            )
            log.info("已发送 WebRTC offer")

            async for message in ws:
                if not self._running:
                    break
                msg = json.loads(message)
                v = msg.get("value", {})
                if msg.get("type") == "webrtc" and v.get("type") == "answer":
                    await pc.setRemoteDescription(RTCSessionDescription(sdp=v["sdp"], type="answer"))
                    log.info("收到 answer，已 setRemoteDescription")
                elif msg.get("type") == "webrtc" and v.get("ice") is not None:
                    cand = v["ice"]
                    if isinstance(cand, str):
                        cand = RTCIceCandidate.from_json(cand)
                    await pc.addIceCandidate(cand)
                    log.info("收到 ICE candidate")

        await pc.close()
        self._pc = None
        self._ws = None

    async def _recv_webrtc(self, track: Any) -> None:
        count = 0
        while self._running:
            try:
                frame = await track.recv()
            except Exception as e:
                log.warning(f"接收帧失败: {e}")
                break
            self._latest = frame.to_ndarray(format="bgr24")
            self._frame_ready.set()
            count += 1
            if count == 1:
                log.info(f"首帧解码成功 shape={self._latest.shape}")
```

main.py

```python
import asyncio
from detector import Detector
from log import get_logger, setup as log_setup
from ws import WebSocketClient

log = get_logger("main")

STREAM = {
    "name": "camera_01",
    "url": "http://127.0.0.1:1984/stream.html?src=camera_01",
}
WS_URL = "ws://localhost:4000/ws/detect"


def main() -> None:
    log_setup()

    ws_client = WebSocketClient(WS_URL)
    ws_client.start()

    detector = Detector(
        ws_client=ws_client,
        stream_url=STREAM["url"],
        stream_name=STREAM["name"],
    )

    log.info(f"启动检测器, 流: {STREAM['name']}, 拉流通道: {detector.source_url}")
    try:
        asyncio.run(detector.run())
    except KeyboardInterrupt:
        log.info("收到中断信号，正在退出...")
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

  @stream %{
    name: "camera_01",
    url: "http://127.0.0.1:1984/stream.html?src=camera_01"
  }

  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(@pubsub, @topic)
    end

    {:ok,
     assign(socket,
       stream: @stream,
       connected: false,
       count: 0,
       fps: 0.0,
       object_count: 0
     )}
  end

  def handle_info({:raw_detection, text}, socket) do
    result =
      case Jason.decode(text) do
        {:ok, data} when is_map(data) ->
          incoming_name = data["stream"] || data["name"]

          if incoming_name != @stream.name do
            :ignore
          else
            dets = normalize_detections(data)
            raw_fps = data["fps"] || data["frame_rate"] || data["framerate"] || data["FPS"]
            fps_val = parse_fps(raw_fps, socket.assigns.fps)
            {:ok, dets, fps_val, socket.assigns.count + 1}
          end

        {:ok, _} ->
          {:ok, [], socket.assigns.fps, socket.assigns.count}

        {:error, reason} ->
          Logger.error("Failed to decode JSON: #{inspect(reason)}, text: #{text}")
          {:ok, [], socket.assigns.fps, socket.assigns.count}
      end

    case result do
      :ignore ->
        {:noreply, socket}

      {:ok, detections, fps, count} ->
        {:noreply,
         socket
         |> assign(:connected, true)
         |> assign(:object_count, length(detections))
         |> assign(:count, count)
         |> assign(:fps, fps)
         |> push_event("detections", %{detections: detections})}
    end
  end

  defp parse_fps(raw, fallback) do
    case raw do
      n when is_number(n) ->
        n / 1

      s when is_binary(s) ->
        case Float.parse(s) do
          {f, _} ->
            f

          :error ->
            case Integer.parse(s) do
              {i, _} -> i / 1
              :error -> fallback
            end
        end

      _ ->
        fallback
    end
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

stream_live.html.heex

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
      <div class="relative rounded-xl overflow-hidden shadow-2xl border border-gray-700 bg-black">
        <div class="flex items-center justify-between px-3 py-2 bg-gray-900/80">
          <span class="text-sm font-medium text-gray-200">{@stream.name}</span>
          <span class="text-xs text-gray-500 truncate max-w-[16rem]">{@stream.url}</span>
        </div>
        <div
          id="yolo-player-0"
          class="relative w-full aspect-video bg-black overflow-hidden"
        >
          <iframe
            src={@stream.url}
            class="absolute inset-0 w-full h-full border-0 pointer-events-none"
            allow="autoplay; fullscreen; picture-in-picture"
          >
          </iframe>
          <canvas
            id="yolo-overlay"
            phx-hook=".Player"
            phx-update="ignore"
            class="absolute inset-0 w-full h-full pointer-events-none z-10"
          >
          </canvas>
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
