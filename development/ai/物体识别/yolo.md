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
import asyncio
import threading
import websockets
import log

logger = log.get_logger(__name__)

_DROP_MARK = object()


class WebSocketClient:
    RECONNECT_INTERVAL = 3.0
    QUEUE_MAX = 16

    def __init__(self, url: str):
        self.url = url
        self._loop: asyncio.AbstractEventLoop | None = None
        self._thread: threading.Thread | None = None
        self._running = False
        self._send_queue: asyncio.Queue | None = None
        self._connected = threading.Event()

    def start(self):
        self._running = True
        self._send_queue = asyncio.Queue(maxsize=self.QUEUE_MAX)
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def send(self, msg: str):
        if not self._running or self._loop is None or self._send_queue is None:
            return
        try:
            asyncio.run_coroutine_threadsafe(self._put(msg), self._loop)
        except Exception:
            pass

    def stop(self):
        self._running = False
        self._connected.clear()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=5)

    @property
    def connected(self) -> bool:
        return self._connected.is_set()

    async def _put(self, msg):
        q = self._send_queue
        try:
            q.put_nowait(msg)
        except asyncio.QueueFull:
            try:
                q.get_nowait()
                q.put_nowait(msg)
            except Exception:
                pass

    def _run(self):
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        try:
            self._loop.run_until_complete(self._connect_loop())
        except Exception:
            logger.exception("ws loop crashed")
        finally:
            self._connected.clear()
            self._loop.close()

    async def _connect_loop(self):
        while self._running:
            try:
                async with websockets.connect(self.url, ping_interval=20) as ws:
                    self._connected.set()
                    logger.info("ws connected: %s", self.url)
                    self._drop_pending()
                    await self._drain_queue(ws)
            except (OSError, asyncio.TimeoutError, websockets.ConnectionClosed):
                self._on_disconnect()
            except Exception:
                self._on_disconnect()

    def _on_disconnect(self):
        self._connected.clear()
        if self._running:
            logger.info("ws disconnected, retry in %.1fs", self.RECONNECT_INTERVAL)
            asyncio.ensure_future(asyncio.sleep(self.RECONNECT_INTERVAL))

    async def _drain_queue(self, ws):
        while self._running:
            try:
                msg = await asyncio.wait_for(self._send_queue.get(), timeout=1.0)
                if msg is _DROP_MARK:
                    continue
                await ws.send(msg)
            except asyncio.TimeoutError:
                continue
            except websockets.ConnectionClosed:
                break
            except Exception:
                continue

    def _drop_pending(self):
        q = self._send_queue
        if q is None:
            return
        dropped = 0
        try:
            while True:
                q.get_nowait()
                dropped += 1
        except asyncio.QueueEmpty:
            pass
        if dropped:
            logger.info("ws dropped %d stale queued messages", dropped)
```

detector.py

```python
import itertools
import json
import time
import log
from ultralytics import YOLO

logger = log.get_logger(__name__)


def _collect_objects(result, model) -> list[dict]:
    objects = []
    if result.boxes is None:
        return objects

    for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
        cls_id = int(box.cls[0])
        cx = (x1 + x2) / 2
        cy = (y1 + y2) / 2
        w = x2 - x1
        h = y2 - y1
        objects.append(
            {
                "class": model.names[cls_id],
                "cx": cx,
                "cy": cy,
                "w": w,
                "h": h,
            }
        )

    return objects


def _frame_shape(result) -> tuple[int, int]:
    h, w = result.orig_shape
    return int(w), int(h)


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
    def __init__(self, ws_client, model_path, conf_thresh):
        self.ws_client = ws_client
        self.conf_thresh = conf_thresh
        self.model = YOLO(model_path)
        self.model.add_callback("on_predict_batch_end", self._on_batch_end)
        self.fps_gen = _fps_generator()
        self.fps = 0.0

    def predict(self, source, stop_flag):
        logger.info("等待 liveview: %s", source)
        while not stop_flag.is_set():
            try:
                for _ in self.model.predict(
                    source=source,
                    stream=True,
                    conf=self.conf_thresh,
                    verbose=False,
                ):
                    if stop_flag.is_set():
                        break
            except KeyboardInterrupt:
                stop_flag.set()
                break
            except Exception as e:
                logger.warning("predict 终止: %s: %s, %ds 后重试", type(e).__name__, e, 3)
                self._sleep_until(stop_flag, 3)

    @staticmethod
    def _sleep_until(stop_flag, seconds):
        stop_flag.wait(seconds)

    def _on_batch_end(self, predictor):
        if not predictor.results:
            return

        objects = []
        frame_w, frame_h = 0, 0
        for r in predictor.results:
            objects += _collect_objects(r, self.model)
            frame_w, frame_h = _frame_shape(r)

        new_fps = next(self.fps_gen)
        if new_fps is not None:
            self.fps = new_fps

        ts = int(time.time() * 1000)
        msg = json.dumps(
            {
                "ts": ts,
                "frame": {"w": frame_w, "h": frame_h},
                "objects": objects,
                "fps": round(self.fps, 1),
            }
        )
        self.ws_client.send(msg)
```

log.py

```python
import logging
import sys


def setup(level=logging.DEBUG):
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

    # 设置第三方库的日志级别（避免噪音）
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("ultralytics").setLevel(logging.ERROR)


def get_logger(name):
    return logging.getLogger(name)
```

main.py

```python
import logging
import signal
import threading
import log
from ws import WebSocketClient
from detector import Detector

log.setup(level=logging.INFO)
logger = log.get_logger(__name__)

MODEL_PATH = "model/yolo26s-seg.pt"
CONF_THRESH = 0.5


def main(ws_server, rtsp):
    websocket = WebSocketClient(ws_server)
    websocket.start()

    detector = Detector(websocket, MODEL_PATH, CONF_THRESH)

    stop_flag = threading.Event()
    signal.signal(signal.SIGINT, lambda s, f: stop_flag.set())

    detector.predict(rtsp, stop_flag)

    logger.debug("shutting down")
    websocket.stop()


if __name__ == "__main__":
    main(
        "ws://localhost:4000/ws/yolo/websocket",
        "rtsp://127.0.0.1:8554/camera_01",
    )
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
  @behaviour Phoenix.Socket.Transport

  @pubsub_topic "yolo:frames"

  require Logger

  @impl Phoenix.Socket.Transport
  def child_spec(_opts), do: :ignore

  @impl Phoenix.Socket.Transport
  def connect(state), do: {:ok, state}

  @impl Phoenix.Socket.Transport
  def init(state) do
    Logger.info("[YoloFrameSocket] detector connected")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in({text, _opcode}, state) do
    case Jason.decode(text) do
      {:ok, %{"ts" => ts, "objects" => objects, "fps" => fps} = data} ->
        frame = data["frame"] || %{"w" => 0, "h" => 0}
        payload = normalize(ts, frame, objects, fps)
        Phoenix.PubSub.broadcast(WebDemo.PubSub, @pubsub_topic, {:yolo_frame, payload})
        {:ok, state}

      {:ok, other} ->
        Logger.warning("[YoloFrameSocket] unexpected payload: #{inspect(other)}")
        {:ok, state}

      {:error, _} ->
        Logger.warning("[YoloFrameSocket] non-JSON message ignored")
        {:ok, state}
    end
  end

  @impl Phoenix.Socket.Transport
  def handle_info(msg, state) do
    Logger.debug("[YoloFrameSocket] unexpected info: #{inspect(msg)}")
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def terminate(reason, _state) do
    Logger.info("[YoloFrameSocket] detector disconnected: #{inspect(reason)}")
    Phoenix.PubSub.broadcast(WebDemo.PubSub, @pubsub_topic, {:yolo_disconnect})
    :ok
  end

  defp normalize(ts, frame, objects, fps) do
    objects =
      for obj <- objects || [] do
        %{
          "class" => obj["class"],
          "cx" => obj["cx"],
          "cy" => obj["cy"],
          "w" => obj["w"],
          "h" => obj["h"]
        }
      end

    %{ts: ts, frame: frame, objects: objects, fps: fps}
  end
end
```

yolo_live.ex

```elixir
defmodule WebDemoWeb.YoloLive do
  use WebDemoWeb, :live_view

  @pubsub_topic "yolo:frames"

  @max_sidebar 24
  @stats_throttle_ms 500

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebDemo.PubSub, @pubsub_topic)
    end

    socket =
      socket
      |> assign(:connected, false)
      |> assign(:objects, [])
      |> assign(:count, 0)
      |> assign(:fps, 0.0)
      |> assign(:latency_ms, nil)
      |> assign(:last_ts, nil)
      |> assign(:frame_count, 0)
      |> assign(:last_stats_at, 0)

    {:ok, socket}
  end

  @impl true
  def handle_info({:yolo_frame, %{ts: ts, frame: _frame, objects: objects, fps: fps}}, socket) do
    frame_count = socket.assigns.frame_count + 1
    now_ms = System.system_time(:millisecond)
    last_stats_at = socket.assigns.last_stats_at

    socket =
      if now_ms - last_stats_at >= @stats_throttle_ms do
        sidebar = Enum.take(objects, @max_sidebar)
        latency = now_ms - ts

        socket
        |> assign(:connected, true)
        |> assign(:objects, sidebar)
        |> assign(:count, frame_count)
        |> assign(:fps, fps)
        |> assign(:latency_ms, latency)
        |> assign(:last_ts, ts)
        |> assign(:frame_count, frame_count)
        |> assign(:last_stats_at, now_ms)
      else
        assign(socket, :frame_count, frame_count)
      end

    # 方框渲染走直连 viewer WS（/ws/yolo/view），不经过 LiveView
    {:noreply, socket}
  end

  @impl true
  def handle_info({:yolo_disconnect}, socket) do
    socket =
      socket
      |> assign(:connected, false)
      |> assign(:objects, [])
      |> assign(:count, 0)
      |> assign(:fps, 0.0)
      |> assign(:latency_ms, nil)
      |> assign(:last_ts, nil)
      |> assign(:frame_count, 0)
      |> assign(:last_stats_at, 0)

    {:noreply, socket}
  end
end
```

yolo_live.html.heex

```html
<Layouts.app flash={@flash} current_scope={%{}}>
  <div class="flex flex-col items-center min-h-screen bg-gray-950 p-4 gap-4">
    <div class="flex items-center justify-between w-full max-w-5xl">
      <h1 class="text-2xl font-bold text-white">YOLO 实时识别</h1>
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

    <div class="relative w-full max-w-5xl rounded-xl overflow-hidden shadow-2xl border border-gray-700 bg-black">
      <div
        id="yolo-player"
        phx-hook="YoloPlayer"
        phx-update="ignore"
        class="relative w-full aspect-video bg-black"
        data-src="http://127.0.0.1:1984/api/ws?src=camera_01"
      >
        <canvas
          id="yolo-overlay"
          class="absolute inset-0 w-full h-full pointer-events-none"
        >
        </canvas>
      </div>
    </div>

    <div class="flex flex-wrap gap-3 text-sm text-gray-200 w-full max-w-5xl">
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-eye" class="w-4 h-4 text-sky-400" />
        <span class="text-gray-400">检测帧数</span>
        <span class="font-semibold text-white tabular-nums">{@count}</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-bolt" class="w-4 h-4 text-amber-400" />
        <span class="text-gray-400">帧率</span>
        <span class="font-semibold text-white tabular-nums">{Float.round(@fps, 1)} FPS</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-squares-2x2" class="w-4 h-4 text-emerald-400" />
        <span class="text-gray-400">目标数</span>
        <span class="font-semibold text-white tabular-nums">{length(@objects)}</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-clock" class="w-4 h-4 text-violet-400" />
        <span class="text-gray-400">延迟</span>
        <span class="font-semibold text-white tabular-nums">
          {if(is_nil(@latency_ms), do: "--", else: "#{@latency_ms} ms")}
        </span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-adjustments-horizontal" class="w-4 h-4 text-sky-400" />
        <span class="text-gray-400">同步延迟</span>
        <input
          id="yolo-sync"
          type="range"
          min="0"
          max="600"
          step="10"
          value="150"
          class="w-32 accent-sky-500"
        />
        <span id="yolo-sync-value" class="font-semibold text-white tabular-nums">150 ms</span>
      </div>
    </div>
  </div>
</Layouts.app>
```
