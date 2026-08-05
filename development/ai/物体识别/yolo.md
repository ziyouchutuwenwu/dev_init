# yolo

## 说明

go2rtc 生成 webrtc

python 检测 webrtc, websocket 发送给 elixir

elixir 通过 js 同步坐标和视频

## 准备

go2rtc

## 代码

### python

依赖库

```sh
aiortc
ultralytics
websockets
```

detector.py

```python
import gc
import queue
import threading
import time
from typing import Any
from ultralytics import YOLO
from log import get_logger

logger = get_logger("Detector")


class Detector:
    def __init__(
        self,
        frame_queue: "queue.Queue[tuple[Any, int]]",
        output_queue: "queue.Queue[dict]",
        stream_id: str,
        model_path: str = "models/yolo11n.pt",
        conf_threshold: float = 0.4,
    ) -> None:
        self.frame_queue = frame_queue
        self.output_queue = output_queue
        self.stream_id = stream_id
        self.model_path = model_path
        self.conf_threshold = conf_threshold
        self.running = False
        self.model = YOLO(model_path)

        self._thread: threading.Thread | None = None
        self._processed = 0
        self._dropped = 0
        self._fps = 0.0

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._thread = threading.Thread(
            target=self.start_inference_loop, name="ai-inference", daemon=True
        )
        self._thread.start()

    def stop(self) -> None:
        self.running = False

    def join(self, timeout: float = 5.0) -> None:
        if self._thread:
            self._thread.join(timeout)

    def release(self) -> None:
        self.model = None
        gc.collect()
        _empty_cuda_cache()
        logger.info("YOLO 模型已卸载，显存已释放")

    def start_inference_loop(self) -> None:
        self.running = True
        logger.info(
            f"YOLOv11 推理线程已激活 model={self.model_path} "
            f"conf={self.conf_threshold}"
        )
        window_start = time.monotonic()
        window_frames = 0

        while self.running:
            try:
                frame, rtp_timestamp = self.frame_queue.get(timeout=1.0)
            except queue.Empty:
                continue

            try:
                img_bgr = frame.to_ndarray(format="bgr24")

                results = self.model(
                    img_bgr,
                    verbose=False,
                    conf=self.conf_threshold,
                    stream=True,
                )
                detected_boxes = self._collect_boxes(results)

                window_frames += 1
                elapsed = time.monotonic() - window_start
                if elapsed >= 1.0:
                    self._fps = window_frames / elapsed
                    window_frames = 0
                    window_start = time.monotonic()

                self._emit(
                    {
                        "stream": self.stream_id,
                        "timestamp": rtp_timestamp,
                        "boxes": detected_boxes,
                    }
                )
            except Exception as e:
                logger.error(f"YOLO 推理层异常: {e}")
            finally:
                del frame
                self._housekeeping()

        logger.info("推理线程已退出")

    def _collect_boxes(self, results: Any) -> list[dict]:
        detected_boxes: list[dict] = []
        for result in results:
            if result.boxes is None:
                continue
            for box in result.boxes:
                xyxy = box.xyxy.tolist()[0]
                conf = float(box.conf[0])
                cls = int(box.cls[0])
                detected_boxes.append(
                    {
                        "x": int(xyxy[0]),
                        "y": int(xyxy[1]),
                        "w": int(xyxy[2] - xyxy[0]),
                        "h": int(xyxy[3] - xyxy[1]),
                        "label": self.model.names[cls],
                        "confidence": round(conf, 2),
                    }
                )
        return detected_boxes

    def _emit(self, payload: dict) -> None:
        try:
            self.output_queue.put_nowait(payload)
        except queue.Full:
            self._dropped += 1
            if self._dropped % 100 == 1:
                logger.warning(f"通信队列已满，累计丢弃 {self._dropped} 条检测结果")

    def _housekeeping(self) -> None:
        self._processed += 1
        if self._processed % 300:
            return
        gc.collect()
        _empty_cuda_cache()
        logger.debug(f"已推理 {self._processed} 帧，当前 {self._fps:.1f} FPS")


def _empty_cuda_cache() -> None:
    try:
        import torch

        if torch.cuda.is_available():
            torch.cuda.empty_cache()
    except Exception:
        pass
```

log.py

```python
import logging
import sys


def setup(level: int | str = logging.INFO) -> None:
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

    logging.getLogger("asyncio").setLevel(logging.INFO)
    logging.getLogger("ultralytics").setLevel(logging.WARNING)
    logging.getLogger("websockets").setLevel(logging.WARNING)
    logging.getLogger("aioice").setLevel(logging.WARNING)
    logging.getLogger("aiortc").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("aiortc.codecs.h264").setLevel(logging.ERROR)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
```

main.py

```python
from urllib.parse import urlsplit, urlunsplit
from log import setup as log_setup
from scheduler import Scheduler


def to_ws_url(webrtc_url: str) -> str:
    parts = urlsplit(webrtc_url)
    scheme = parts.scheme.replace("http", "ws")
    path = parts.path.replace("/stream.html", "/api/ws")
    return urlunsplit((scheme, parts.netloc, path, parts.query, parts.fragment))


STREAM = {
    "id": "camera_01",
    "url": "http://127.0.0.1:1984/stream.html?src=camera_01",
}
NOTIFY_URL = "ws://127.0.0.1:4000/ws/detect"


def main() -> None:
    log_setup("INFO")

    stream_ws_url = to_ws_url(STREAM["url"])
    scheduler = Scheduler(
        stream={"id": STREAM["id"], "url": stream_ws_url},
        notify_url=NOTIFY_URL,
    )
    scheduler.install_signal_handlers()
    scheduler.start()
    try:
        scheduler.wait()
    finally:
        scheduler.stop()


if __name__ == "__main__":
    main()
```

rtc.py

```python
import asyncio
import queue
from typing import Any
from aiortc import RTCPeerConnection, RTCSessionDescription
from log import get_logger

logger = get_logger("Rtc")

RTP_TIMESTAMP_MASK = 0xFFFFFFFF


class Rtc:
    def __init__(self, frame_queue: "queue.Queue[tuple[Any, int]]", session_over: asyncio.Event) -> None:
        self.frame_queue = frame_queue
        self.session_over = session_over
        self.pc: RTCPeerConnection | None = None
        self._capture_task: asyncio.Task | None = None
        self._rtp_origin: int | None = None
        self._dropped = 0
        self.running = True

    async def negotiate(self) -> str:
        self.pc = RTCPeerConnection()
        pc = self.pc
        session_over = self.session_over

        @pc.on("track")
        def on_track(track: Any) -> None:
            if track.kind != "video":
                return
            logger.info("成功订阅网关 WebRTC 视频轨道")
            self._capture_task = asyncio.ensure_future(self._capture_loop(track))

        @pc.on("connectionstatechange")
        async def on_connectionstatechange() -> None:
            logger.info(f"PeerConnection 状态: {pc.connectionState}")
            if pc.connectionState in ("failed", "closed", "disconnected"):
                session_over.set()

        pc.addTransceiver("video", direction="recvonly")
        await pc.setLocalDescription(await pc.createOffer())
        return pc.localDescription.sdp

    async def set_remote_description(self, sdp: str) -> None:
        await self.pc.setRemoteDescription(RTCSessionDescription(sdp=sdp, type="answer"))
        logger.info("收到 answer，已 setRemoteDescription")

    async def add_ice_candidate(self, candidate: Any) -> None:
        await self.pc.addIceCandidate(candidate)

    async def teardown(self) -> None:
        if self._capture_task is not None:
            self._capture_task.cancel()
            try:
                await self._capture_task
            except (asyncio.CancelledError, Exception):
                pass
            self._capture_task = None
        if self.pc is not None:
            await self.pc.close()
            self.pc = None

    async def _capture_loop(self, track: Any) -> None:
        received = 0
        while self.running:
            try:
                frame = await track.recv()
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.error(f"WebRTC 帧接收中断: {e}")
                break

            if frame is None:
                continue

            rtp_timestamp = (
                self._resolve_rtp_origin(track) + int(frame.pts)
            ) & RTP_TIMESTAMP_MASK

            received += 1
            if received == 1:
                logger.info(
                    f"首帧到达 {frame.width}x{frame.height} "
                    f"rtpTimestamp={rtp_timestamp}"
                )

            if self.frame_queue.full():
                try:
                    self.frame_queue.get_nowait()
                    self._dropped += 1
                    if self._dropped % 100 == 0:
                        logger.debug(f"推理跟不上收流，已累计丢弃 {self._dropped} 帧")
                except queue.Empty:
                    pass

            try:
                self.frame_queue.put_nowait((frame, rtp_timestamp))
            except queue.Full:
                pass

        if self.session_over is not None:
            self.session_over.set()

    def _resolve_rtp_origin(self, track: Any) -> int:
        if self._rtp_origin is not None:
            return self._rtp_origin

        origin = None
        if self.pc is not None:
            for receiver in self.pc.getReceivers():
                if receiver.track is not track:
                    continue
                mapper = getattr(receiver, "_RTCRtpReceiver__timestamp_mapper", None)
                origin = getattr(mapper, "_origin", None)
                break

        if origin is None:
            logger.warning("未能读取 RTP origin，退化为使用归一化后的 pts")
            origin = 0
        self._rtp_origin = int(origin)
        return self._rtp_origin
```

scheduler.py

```python
import queue
import signal
import threading
from typing import Any
from detector import Detector
from log import get_logger
from stream import Stream
from ws_client import WsClient

logger = get_logger("Scheduler")


class Scheduler:
    def __init__(self, stream: dict, notify_url: str) -> None:
        self.stream = stream
        self.notify_url = notify_url
        self.frame_queue: "queue.Queue[tuple[Any, int]]" = queue.Queue(
            maxsize=2
        )
        self.output_queue: "queue.Queue[Any]" = queue.Queue(
            maxsize=30
        )

        self.reader = Stream(self.frame_queue, stream)
        self.engine = Detector(
            self.frame_queue,
            self.output_queue,
            stream["id"],
        )
        self.broker = WsClient(self.output_queue, notify_url)

        self._shutdown = threading.Event()

    def install_signal_handlers(self) -> None:
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, self._on_signal)

    def _on_signal(self, signum: int, _frame: Any) -> None:
        if self._shutdown.is_set():
            return
        logger.info(f"收到信号 {signal.Signals(signum).name}，开始优雅退出...")
        self._shutdown.set()

    def start(self) -> None:
        logger.info(f"订阅通道: {self.stream['url']}")
        logger.info(f"下游中转: {self.notify_url}")
        self.broker.start()
        self.engine.start()
        self.reader.start()

    def wait(self) -> None:
        while not self._shutdown.wait(timeout=1.0):
            pass

    def stop(self) -> None:
        logger.info("[1/3] 关闭 WebRTC PeerConnection...")
        self.reader.stop()
        self.reader.join()

        logger.info("[2/3] 停止 YOLO 推理并释放显存...")
        self.engine.stop()
        self.engine.join()
        self.engine.release()

        logger.info("[3/3] 断开下游 WebSocket...")
        self.broker.stop()
        self.broker.join()

        logger.info("引擎已完全停止")
```

signaling.py

```python
import json
from typing import Any
import websockets
from aiortc.sdp import candidate_from_sdp
from log import get_logger
from rtc import Rtc

logger = get_logger("Signaling")


class Signaling:
    def __init__(self, rtc: Rtc, ws_url: str) -> None:
        self.rtc = rtc
        self.ws_url = ws_url
        self._ws: Any = None

    async def run(self, offer_sdp: str) -> None:
        try:
            async with websockets.connect(
                self.ws_url,
                ping_interval=10,
                ping_timeout=5,
            ) as ws:
                self._ws = ws
                await ws.send(
                    json.dumps(
                        {
                            "type": "webrtc",
                            "value": {
                                "type": "offer",
                                "sdp": offer_sdp,
                            },
                        }
                    )
                )
                logger.info("已发送 WebRTC offer，等待网关 answer")
                await self._loop(ws)
        finally:
            self._ws = None

    async def _loop(self, ws: Any) -> None:
        async for message in ws:
            if not self.rtc.running:
                return
            try:
                msg = json.loads(message)
            except (TypeError, ValueError):
                continue

            kind, data = _extract_signal(msg)
            if kind == "answer" and data:
                await self.rtc.set_remote_description(data)
            elif kind == "candidate":
                candidate = _parse_candidate(data)
                if candidate is not None:
                    await self.rtc.add_ice_candidate(candidate)


def _extract_signal(msg: Any) -> tuple[str | None, Any]:
    if not isinstance(msg, dict):
        return None, None
    kind = msg.get("type")
    value = msg.get("value")

    if kind == "webrtc/answer" and isinstance(value, str):
        return "answer", value
    if isinstance(value, dict) and value.get("type") == "answer":
        return "answer", value.get("sdp")
    if kind == "webrtc/candidate":
        return "candidate", value
    if isinstance(value, dict) and value.get("ice") is not None:
        return "candidate", value["ice"]
    return None, None


def _parse_candidate(raw: Any) -> Any:
    if not raw:
        return None

    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except ValueError:
            raw = {"candidate": raw}

    if not isinstance(raw, dict):
        return None

    sdp = raw.get("candidate") or ""
    if not sdp:
        return None
    if sdp.startswith("candidate:"):
        sdp = sdp[len("candidate:"):]

    try:
        candidate = candidate_from_sdp(sdp)
    except ValueError:
        return None
    candidate.sdpMid = raw.get("sdpMid")
    candidate.sdpMLineIndex = raw.get("sdpMLineIndex") or 0
    return candidate
```

stream.py

```python
import asyncio
import queue
import threading
from typing import Any
from log import get_logger
from rtc import Rtc
from signaling import Signaling

logger = get_logger("Stream")


class Stream:
    def __init__(self, frame_queue: "queue.Queue[tuple[Any, int]]", stream: dict) -> None:
        self.frame_queue = frame_queue
        self.signaling_ws_url = stream["url"]
        self.running = False
        self._thread: threading.Thread | None = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._rtc: Rtc | None = None
        self._session_over: asyncio.Event | None = None

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self.running = True
        self._thread = threading.Thread(
            target=self._thread_main, name="stream-reader", daemon=True
        )
        self._thread.start()

    def stop(self) -> None:
        self.running = False
        if self._rtc is not None:
            self._rtc.running = False
        if self._loop is not None and not self._loop.is_closed():
            self._loop.call_soon_threadsafe(self._wake_up)

    def join(self, timeout: float = 5.0) -> None:
        if self._thread:
            self._thread.join(timeout)

    def _wake_up(self) -> None:
        if self._session_over is not None:
            self._session_over.set()

    def _thread_main(self) -> None:
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        try:
            self._loop.run_until_complete(self._supervise())
        finally:
            self._loop.close()
            logger.info("解码线程已退出")

    async def _supervise(self) -> None:
        while self.running:
            try:
                await self._negotiate()
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.error(f"WebRTC 会话异常: {e}")
            if not self.running:
                break
            logger.info(f"3.0s 后重新订阅网关...")
            await asyncio.sleep(3.0)

    async def _negotiate(self) -> None:
        session_over = asyncio.Event()
        rtc = Rtc(self.frame_queue, session_over)
        self._rtc = rtc
        self._session_over = session_over

        offer_sdp = await rtc.negotiate()
        logger.info(f"连接网关信令: {self.signaling_ws_url}")
        signaling = Signaling(rtc, self.signaling_ws_url)
        sig = asyncio.ensure_future(signaling.run(offer_sdp))
        closing = asyncio.ensure_future(session_over.wait())
        done, pending = await asyncio.wait(
            [sig, closing], return_when=asyncio.FIRST_COMPLETED
        )
        for task in pending:
            task.cancel()
        for task in done:
            task.result()
        await rtc.teardown()
```

ws_client.py

```python
import asyncio
import json
import queue
import threading
from typing import Any
import websockets
from websockets.exceptions import ConnectionClosed
from log import get_logger

logger = get_logger("WsClient")

_SHUTDOWN = object()


class WsClient:
    def __init__(self, output_queue: "queue.Queue[Any]", notify_url: str) -> None:
        self.output_queue = output_queue
        self.notify_url = notify_url
        self.running = False

        self._thread: threading.Thread | None = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._ws: Any = None
        self._sent = 0

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self.running = True
        self._thread = threading.Thread(
            target=self._thread_main, name="ws-client", daemon=True
        )
        self._thread.start()

    def stop(self) -> None:
        self.running = False
        try:
            self.output_queue.put_nowait(_SHUTDOWN)
        except queue.Full:
            pass
        if self._loop is not None and not self._loop.is_closed():
            self._loop.call_soon_threadsafe(lambda: None)

    def join(self, timeout: float = 5.0) -> None:
        if self._thread:
            self._thread.join(timeout)

    def _thread_main(self) -> None:
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)
        try:
            self._loop.run_until_complete(self._connect_forever())
        finally:
            self._loop.close()
            logger.info("通信线程已退出")

    async def _connect_forever(self) -> None:
        delay = 1.0
        while self.running:
            try:
                async with websockets.connect(
                    self.notify_url,
                    ping_interval=10,
                    ping_timeout=5,
                ) as ws:
                    self._ws = ws
                    logger.info(f"已连接下游中转服务: {self.notify_url}")
                    delay = 1.0
                    await self._pump(ws)
            except ConnectionClosed as e:
                logger.warning(f"下游 WebSocket 断开: {e}")
            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.warning(f"下游 WebSocket 连接失败: {e}")
            finally:
                self._ws = None

            if not self.running:
                break
            logger.info(f"{delay:.1f}s 后重连下游...")
            await asyncio.sleep(delay)
            delay = min(delay * 2, 5.0)

    async def _pump(self, ws: Any) -> None:
        loop = asyncio.get_running_loop()
        while self.running:
            payload = await loop.run_in_executor(None, self._take)
            if payload is None:
                continue
            if payload is _SHUTDOWN:
                return
            await ws.send(json.dumps(payload, ensure_ascii=False))
            self._sent += 1
            if self._sent % 300 == 0:
                logger.debug(f"已下发 {self._sent} 条检测结果")

    def _take(self) -> Any:
        try:
            return self.output_queue.get(timeout=0.5)
        except queue.Empty:
            return None
```

### elixir

assets/js/hook/rtc.js

```javascript
import {Socket} from "phoenix";

const MAX_HOLD_TICKS = 45000;
const MAX_QUEUE = 120;
const WEBRTC_PORT = 1984;

const LABEL_COLORS = {
  person: "#4ade80",
  car: "#60a5fa",
  truck: "#60a5fa",
  bus: "#60a5fa",
  bicycle: "#facc15",
  motorcycle: "#facc15",
  dog: "#f472b6",
  cat: "#f472b6",
  bird: "#c084fc",
  "traffic light": "#fb923c",
  "fire hydrant": "#f87171",
  "stop sign": "#f87171",
};
const DEFAULT_COLOR = "#f87171";

function webrtcWsUrl(host, stream) {
  const proto = window.location.protocol === "https:" ? "wss" : "ws";
  return `${proto}://${host}:${WEBRTC_PORT}/api/ws?src=${encodeURIComponent(stream)}`;
}

const Rtc = {
  mounted() {
    this.cameraId = this.el.dataset.cameraId;
    this.video = this.el.querySelector("video");
    this.canvas = this.el.querySelector("canvas");
    this.ctx = this.canvas.getContext("2d");

    this.queue = new Map();
    this._closed = false;

    this.elFps = document.getElementById(`fps-${this.cameraId}`);
    this.elObj = document.getElementById(`obj-${this.cameraId}`);
    this.elPill = document.getElementById(`status-pill-${this.cameraId}`);

    this._boxCount = 0;
    this._fpsWindow = [];
    this._lastBoxAt = 0;
    this._setDetecting(false);

    this._connectChannel();
    this._connectWebRTC();

    this._rvfc = (now, metadata) => this._onFrame(metadata);
    this.video.requestVideoFrameCallback(this._rvfc);

    this._statusTimer = setInterval(() => this._refreshStatus(), 500);
  },

  destroyed() {
    this._closed = true;
    clearInterval(this._statusTimer);
    if (this.channel) this.channel.leave();
    if (this.socket) this.socket.disconnect();
    if (this.ws) try { this.ws.close(); } catch (e) {}
    if (this.pc) try { this.pc.close(); } catch (e) {}
  },

  _connectChannel() {
    this.socket = new Socket("/sync");
    this.socket.connect();

    this.channel = this.socket.channel(`data:${this.cameraId}`, {});
    this.channel.on("sync_boxes", (payload) => this._onBoxes(payload));
    this.channel
      .join()
      .receive("error", () => console.error("[Rtc] 无法加入坐标信道"));
  },

  _onBoxes(payload) {
    if (!payload || payload.timestamp == null || !Array.isArray(payload.boxes)) return;
    this.queue.set(payload.timestamp >>> 0, payload.boxes);

    while (this.queue.size > MAX_QUEUE) {
      this.queue.delete(this.queue.keys().next().value);
    }

    this._fpsWindow.push(performance.now());
    this._boxCount = payload.boxes.length;
    this._lastBoxAt = performance.now();
  },

  _connectWebRTC() {
    const pc = new RTCPeerConnection({
      iceServers: [{urls: "stun:stun.l.google.com:19302"}],
    });
    this.pc = pc;

    pc.addTransceiver("video", {direction: "recvonly"});

    pc.ontrack = (event) => {
      // 方案2b：不设置全局缓冲，视频实时播放；延迟由绘制循环按帧等待框到达来控制
      if (!this.video.srcObject) {
        this.video.srcObject = event.streams[0];
        this.video.play().catch(() => {});
      }
    };

    pc.onicecandidate = (event) => {
      if (event.candidate && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(
          JSON.stringify({type: "webrtc/candidate", value: event.candidate.candidate})
        );
      }
    };

    const ws = new WebSocket(webrtcWsUrl(window.location.hostname, this.cameraId));
    this.ws = ws;

    ws.onopen = async () => {
      await pc.setLocalDescription(await pc.createOffer());
      ws.send(JSON.stringify({type: "webrtc/offer", value: pc.localDescription.sdp}));
    };

    ws.onmessage = async (msg) => {
      const m = JSON.parse(msg.data);
      if (m.type === "webrtc/answer") {
        await pc.setRemoteDescription({type: "answer", sdp: m.value});
      } else if (m.type === "webrtc/candidate") {
        await pc.addIceCandidate({candidate: m.value, sdpMid: "0"});
      } else if (m.type === "error") {
        console.error("[Rtc] webrtc error:", m.value);
      }
    };
  },

  _onFrame(metadata) {
    if (this._closed) return;
    const t = metadata.rtpTimestamp == null ? null : metadata.rtpTimestamp >>> 0;
    if (t != null) {
      this._jsFrameCount = (this._jsFrameCount || 0) + 1;
      if (this._jsFrameCount <= 5 || this._jsFrameCount % 30 === 0) {
        console.log("[Rtc][RTP-DIAG] js rtp", t, "(#" + this._jsFrameCount + ")");
      }
    }
    this._draw(t);
    this.video.requestVideoFrameCallback(this._rvfc);
  },

  _draw(t) {
    const vw = this.video.videoWidth;
    const vh = this.video.videoHeight;
    if (vw && vh) {
      if (this.canvas.width !== vw) this.canvas.width = vw;
      if (this.canvas.height !== vh) this.canvas.height = vh;
    }

    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    if (t == null) return;

    const boxes = this._pick(t);
    if (!boxes || !boxes.length) return;

    const s = this.canvas.width / 1000;
    const fontSize = Math.max(12, Math.round(13 * s));
    const barH = Math.round(fontSize * 1.7);
    const padX = Math.round(fontSize * 0.5);

    this.ctx.lineWidth = Math.max(2, Math.round(3 * s));
    this.ctx.font = `bold ${fontSize}px sans-serif`;
    this.ctx.textBaseline = "middle";

    for (const b of boxes) {
      const color = LABEL_COLORS[b.label] || DEFAULT_COLOR;
      this.ctx.strokeStyle = color;
      this.ctx.strokeRect(b.x, b.y, b.w, b.h);

      const label = `${b.label} ${(b.confidence * 100).toFixed(0)}%`;
      const barW = this.ctx.measureText(label).width + padX * 2;
      const barY = b.y - barH >= 0 ? b.y - barH : b.y;

      this.ctx.fillStyle = color;
      this.ctx.fillRect(b.x, barY, barW, barH);
      this.ctx.fillStyle = "#0f172a";
      this.ctx.fillText(label, b.x + padX, barY + barH / 2);
    }
  },

  // 精确命中本帧 rtp 的框；未到则就近匹配最近旧帧（窗口 MAX_HOLD_TICKS），
  // 这样框以 ≈检测延迟落到随后几帧上，视频保持流畅。
  _pick(t) {
    const exact = this.queue.get(t);
    if (exact) {
      this._dropOlderThan(t);
      return exact;
    }

    let bestKey = null;
    let bestAge = Infinity;
    for (const k of this.queue.keys()) {
      const age = (t - k) | 0;
      if (age > 0 && age <= MAX_HOLD_TICKS && age < bestAge) {
        bestAge = age;
        bestKey = k;
      }
    }
    if (bestKey === null) return null;

    this._dropOlderThan(bestKey);
    return this.queue.get(bestKey);
  },

  _dropOlderThan(key) {
    for (const k of this.queue.keys()) {
      if (((key - k) | 0) > 0) this.queue.delete(k);
    }
  },

  _setDetecting(ok) {
    if (!this.elPill) return;
    this.elPill.className = ok
      ? "px-2.5 py-1 rounded-full font-medium bg-emerald-500/20 text-emerald-300"
      : "px-2.5 py-1 rounded-full font-medium bg-rose-500/20 text-rose-300";
    this.elPill.textContent = ok ? "检测中" : "等待检测器";
  },

  _refreshStatus() {
    const now = performance.now();
    while (this._fpsWindow.length && now - this._fpsWindow[0] > 1000) {
      this._fpsWindow.shift();
    }
    this.elFps.textContent = `${this._fpsWindow.length.toFixed(1)} FPS`;
    this.elObj.textContent = String(this._boxCount);

    this._setDetecting(this._lastBoxAt > 0 && now - this._lastBoxAt < 2000);
  },
};

export {Rtc};
```

app.js

```javascript
import { Rtc } from "./hook/rtc.js";

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, Rtc },
});
```

router.ex

```elixir
scope "/", WebDemoWeb do
  pipe_through :browser

  get "/", PageController, :home
  live "/live", StreamLive
end
```

endpoint.ex

```elixir
# 页面
socket "/live", Phoenix.LiveView.Socket,
  websocket: [connect_info: [session: @session_options]],
  longpoll: [connect_info: [session: @session_options]]

# python 发数据
socket "/ws", WebDemoWeb.BridgeSocket,
  websocket: [
    path: "/detect",
    connect_info: [:x_headers, :uri, :peer_data, session: @session_options]
  ],
  longpoll: false

# 和 js 通信
socket "/sync", WebDemoWeb.UserSocket,
  websocket: [connect_info: [:uri, :peer_data]],
  longpoll: false
```

bridge_socket.ex

```elixir
defmodule WebDemoWeb.BridgeSocket do
  @behaviour WebSock
  require Logger

  @endpoint WebDemoWeb.Endpoint

  def connect(state), do: {:ok, state}

  def init(state), do: connect(state)

  def handle_in({text, _opts}, state) do
    case Jason.decode(text) do
      {:ok, %{"stream" => camera_id, "timestamp" => timestamp, "boxes" => boxes}} ->
        @endpoint.broadcast!("data:" <> to_string(camera_id), "sync_boxes", %{
          timestamp: timestamp,
          boxes: boxes
        })

      {:ok, _other} ->
        :ok

      {:error, reason} ->
        Logger.warning("BridgeSocket 无法解析检测 JSON: #{inspect(reason)}")
    end

    {:ok, state}
  end

  def handle_info(_msg, state), do: {:ok, state}

  def terminate(_reason, _state), do: :ok
end
```

stream_live.ex

```elixir
defmodule WebDemoWeb.StreamLive do
  use WebDemoWeb, :live_view

  @camera_id "camera_01"

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
      camera_id: @camera_id
     )}
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
        <span
          id={"status-pill-#{@camera_id}"}
          class="px-2.5 py-1 rounded-full font-medium bg-rose-500/20 text-rose-300"
        >
          等待检测器
        </span>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 w-full max-w-5xl">
      <div class="relative rounded-xl overflow-hidden shadow-2xl border border-gray-700 bg-black">
        <div class="flex items-center justify-between px-3 py-2 bg-gray-900/80">
          <span class="text-sm font-medium text-gray-200">{@camera_id}</span>
        </div>
        <div
          id={"stage-#{@camera_id}"}
          phx-update="ignore"
          phx-hook="Rtc"
          data-camera-id={@camera_id}
          class="relative w-full bg-black overflow-hidden"
        >
          <video
            id={"video-#{@camera_id}"}
            class="block w-full aspect-video bg-black"
            autoplay
            playsinline
            muted
          >
          </video>
          <canvas
            id={"canvas-#{@camera_id}"}
            class="absolute inset-0 w-full h-full pointer-events-none"
          >
          </canvas>
        </div>
      </div>
    </div>

    <div class="flex flex-wrap gap-3 text-sm text-gray-200 w-full max-w-5xl">
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-bolt" class="w-4 h-4 text-amber-400" />
        <span class="text-gray-400">帧率</span>
        <span id={"fps-#{@camera_id}"} class="font-semibold text-white tabular-nums">0.0 FPS</span>
      </div>
      <div class="flex items-center gap-2 bg-gray-800/80 px-3 py-1.5 rounded-lg">
        <.icon name="hero-squares-2x2" class="w-4 h-4 text-emerald-400" />
        <span class="text-gray-400">目标数</span>
        <span id={"obj-#{@camera_id}"} class="font-semibold text-white tabular-nums">0</span>
      </div>
    </div>
  </div>
</Layouts.app>
```
