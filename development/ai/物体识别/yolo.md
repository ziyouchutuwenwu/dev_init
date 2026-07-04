# yolo

## 说明

python 实现功能

elixir 展示

## 代码

### python

依赖库

```sh
loguru
ultralytics
websockets
```

ws.py

```python
import asyncio
import threading
import websockets
from loguru import logger


class WebSocketClient:
    def __init__(self, url: str):
        self.url = url
        self._loop: asyncio.AbstractEventLoop | None = None
        self._thread: threading.Thread | None = None
        self._running = False
        self._send_queue: asyncio.Queue | None = None

    def start(self):
        self._running = True
        self._send_queue = asyncio.Queue()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def send(self, msg: str):
        if not self._running or self._loop is None:
            return
        try:
            asyncio.run_coroutine_threadsafe(self._send_queue.put(msg), self._loop)
        except Exception:
            pass

    def stop(self):
        self._running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=5)

    def _run(self):
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        self._loop.run_until_complete(self._connect_loop())

    async def _connect_loop(self):
        while self._running:
            try:
                async with websockets.connect(self.url, ping_interval=20) as ws:
                    logger.debug("connected {}", self.url)
                    await self._drain_queue(ws)
            except (OSError, asyncio.TimeoutError, websockets.ConnectionClosed):
                if self._running:
                    await asyncio.sleep(3)

    async def _drain_queue(self, ws):
        while self._running:
            try:
                msg = await asyncio.wait_for(self._send_queue.get(), timeout=1.0)
                await ws.send(msg)
            except asyncio.TimeoutError:
                continue
            except websockets.ConnectionClosed:
                break
            except Exception:
                pass
```

detector.py

```python
import base64
import itertools
import json
import time
from loguru import logger
import logging
import cv2
import numpy as np
from ultralytics import YOLO

logging.getLogger("ultralytics").setLevel(logging.ERROR)

CLASS_COLORS = [
    (255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0), (255, 0, 255),
    (0, 255, 255), (128, 0, 0), (0, 128, 0), (0, 0, 128), (128, 128, 0),
]


def _draw_boxes(frame: np.ndarray, result, model) -> list[dict]:
    objects = []
    if result.boxes is None:
        return objects

    for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
        cls_id = int(box.cls[0])
        conf = float(box.conf[0])
        label = f"{model.names[cls_id]} {conf:.2f}"
        color = CLASS_COLORS[cls_id % len(CLASS_COLORS)]

        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(frame, (x1, y1 - th - 6), (x1 + tw + 4, y1), color, -1)
        cv2.putText(
            frame, label, (x1 + 2, y1 - 4),
            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1,
        )

        cx = (x1 + x2) / 2
        cy = (y1 + y2) / 2
        w = x2 - x1
        h = y2 - y1
        objects.append({
            "class": model.names[cls_id],
            "prob": round(conf, 3),
            "bbox": {"cx": cx, "cy": cy, "w": w, "h": h},
        })

    return objects


def _fps_generator():
    count = itertools.count(1)
    timer = time.monotonic()
    while True:
        n = next(count)
        now = time.monotonic()
        elapsed = now - timer
        if elapsed >= 1.0:
            timer = now
            count = itertools.count(1)
            yield n / elapsed
        else:
            yield None


class Detector:
    def __init__(self, ws_client, model_path, conf_thresh, jpeg_quality=60):
        self.ws_client = ws_client
        self.conf_thresh = conf_thresh
        self.jpeg_quality = jpeg_quality
        self.model = YOLO(model_path)
        self.model.add_callback("on_predict_batch_end", self._on_batch_end)
        self.fps_gen = _fps_generator()
        self.fps = 0.0

    def predict(self, source, stop_flag):
        cap = None
        for backend in (cv2.CAP_V4L2, cv2.CAP_ANY):
            c = cv2.VideoCapture(source, backend)
            if c.isOpened():
                cap = c
                break
            c.release()
        if cap is None:
            cap = cv2.VideoCapture(source)
        if not cap.isOpened():
            logger.error("cannot open camera /dev/video{}", source)
            return
        logger.info("等待 liveview")
        try:
            while not stop_flag.is_set():
                ret, frame = cap.read()
                if not ret:
                    time.sleep(0.5)
                    continue
                for _ in self.model.predict(
                    source=frame,
                    conf=self.conf_thresh,
                    verbose=False,
                ):
                    if stop_flag.is_set():
                        break
        except (ConnectionError, KeyboardInterrupt):
            pass
        finally:
            cap.release()
    def _on_batch_end(self, predictor):
        if not predictor.results:
            return

        annotated = None
        objects = []

        for r in predictor.results:
            img = r.orig_img.copy()
            objects += _draw_boxes(img, r, self.model)
            annotated = img

        if annotated is None:
            return

        new_fps = next(self.fps_gen)
        if new_fps is not None:
            self.fps = new_fps


        ok, jpeg = cv2.imencode(".jpg", annotated, [cv2.IMWRITE_JPEG_QUALITY, self.jpeg_quality])
        if not ok:
            return

        frame_b64 = base64.b64encode(jpeg).decode("ascii")
        msg = json.dumps({
            "image": frame_b64,
            "objects": objects,
            "fps": round(self.fps, 1),
        })
        self.ws_client.send(msg)
```

main.py

```python
import signal
import threading
from loguru import logger
from ws import WebSocketClient
from detector import Detector

WS_URL = "ws://localhost:4000/ws/yolo/websocket"
CAMERA_DEVICE = 10
MODEL_PATH = "model/yolo26s-seg.pt"
CONF_THRESH = 0.5

# 0-100
JPEG_QUALITY = 60


def main():
    websocket = WebSocketClient(WS_URL)
    websocket.start()

    detector = Detector(websocket, MODEL_PATH, CONF_THRESH, JPEG_QUALITY)

    stop_flag = threading.Event()
    signal.signal(signal.SIGINT, lambda s, f: stop_flag.set())

    detector.predict(CAMERA_DEVICE, stop_flag)

    logger.debug("shutting down")
    websocket.stop()


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

    live "/", YoloLive, :index
    live "/yolo", YoloLive, :index
  end
end
```

endpoint.ex

```elixir
socket("/ws/yolo", WebDemoWeb.YoloFrameSocket, websocket: [connect_info: []])
```

yolo_frame_socket.ex

```elixir
defmodule WebDemoWeb.YoloFrameSocket do
  @pubsub_topic "yolo:frames"

  require Logger

  def connect(state), do: {:ok, state}

  def init(state), do: {:ok, state}

  def handle_in({text, _opts}, state) do
    case Jason.decode(text) do
      {:ok, %{"image" => image, "objects" => objects, "fps" => fps}} ->
        objects =
          for obj <- objects || [] do
            bbox = obj["bbox"] || %{}
            %{
              class: obj["class"],
              prob: obj["prob"],
              bbox: %{cx: bbox["cx"], cy: bbox["cy"], w: bbox["w"], h: bbox["h"]}
            }
          end

        Phoenix.PubSub.broadcast(WebDemo.PubSub, @pubsub_topic, {:yolo_frame, %{image: image, objects: objects, fps: fps}})
        {:ok, state}

      _ ->
        Logger.warning("unexpected ws message: #{inspect(text)}")
        {:ok, state}
    end
  end

  def handle_info(msg, state) do
    Logger.warning("unexpected info: #{inspect(msg)}")
    {:ok, state}
  end

  def terminate(_reason, _state), do: :ok
end
```

yolo_live.ex

```elixir
defmodule WebDemoWeb.YoloLive do
  use WebDemoWeb, :live_view

  @pubsub_topic "yolo:frames"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebDemo.PubSub, @pubsub_topic)
    end

    socket =
      socket
      |> assign(:image, nil)
      |> assign(:objects, [])
      |> assign(:count, 0)
      |> assign(:fps, 0.0)
      |> assign(:camera_active, false)

    {:ok, socket}
  end

  @impl true
  def handle_info({:yolo_frame, %{image: image, objects: objects, fps: fps}}, socket) do
    socket =
      socket
      |> assign(:image, image)
      |> assign(:objects, objects)
      |> assign(:count, socket.assigns.count + 1)
      |> assign(:fps, fps)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:yolo_disconnect}, socket) do
    socket =
      socket
      |> assign(:image, nil)
      |> assign(:objects, [])
      |> assign(:count, 0)
      |> assign(:fps, 0.0)
      |> assign(:camera_active, false)

    {:noreply, socket}
  end
end
```

yolo_live.html.heex

```html
<Layouts.app flash={@flash} current_scope={%{}}>
  <div class="flex flex-col items-center h-screen overflow-hidden bg-gray-950 p-4">
    <h1 class="text-2xl font-bold text-white mb-4">识别结果</h1>

    <div class="relative bg-black rounded-xl overflow-hidden shadow-2xl border border-gray-700 w-full max-w-5xl max-h-[55vh]">
      <img
        :if={@image}
        src={"data:image/jpeg;base64,#{@image}"}
        class="w-full h-full object-contain"
        alt="检测结果"
      />
      <div
        :if={!@image}
        class="w-full h-full flex items-center justify-center text-gray-400"
      >
        <p>等待摄像头数据...</p>
      </div>
    </div>

    <div class="mt-4 flex gap-4 text-sm text-gray-300">
      <span class="bg-gray-800 px-3 py-1 rounded-md">
        检测帧数: {@count}
      </span>
      <span class="bg-gray-800 px-3 py-1 rounded-md">
        帧率: {Float.round(@fps, 1)} FPS
      </span>
      <span class="bg-gray-800 px-3 py-1 rounded-md">
        目标数: {length(@objects)}
      </span>
    </div>

    <div class="mt-4 w-full max-w-5xl h-60 flex flex-col">
      <h2 class="text-white font-semibold mb-2">检测到的目标:</h2>
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 flex-1 min-h-0 overflow-y-auto">
        <div
          :for={obj <- @objects}
          class="bg-gray-800 text-white text-xs rounded-md truncate h-6 flex items-center justify-center"
        >
          {obj.class} ({Float.round(obj.prob, 2)})
        </div>
      </div>
    </div>
  </div>
</Layouts.app>
```
