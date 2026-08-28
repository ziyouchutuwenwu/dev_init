# web

## 说明

对接 rust 转出来的 webrtc

## 代码

overlay_renderer.js

```javascript
const CLASS_COLORS = [
  "#22c55e",
  "#3b82f6",
  "#f97316",
  "#a855f7",
  "#ec4899",
  "#eab308",
  "#06b6d4",
  "#ef4444",
  "#14b8a6",
  "#8b5cf6",
];

function getColorForClass(clsId, label) {
  if (clsId !== undefined && clsId >= 0) {
    return CLASS_COLORS[clsId % CLASS_COLORS.length];
  }
  if (label && typeof label === "string") {
    let hash = 0;
    for (let i = 0; i < label.length; i++) {
      hash = (hash << 5) - hash + label.charCodeAt(i);
    }
    return CLASS_COLORS[Math.abs(hash) % CLASS_COLORS.length];
  }
  return "#22c55e";
}

export function drawDetections(canvas, video, detections, frameW, frameH) {
  if (!video || !canvas) return;
  const ctx = canvas.getContext("2d");

  const rect = video.getBoundingClientRect();
  const displayW = video.clientWidth || rect.width || 640;
  const displayH = video.clientHeight || rect.height || 480;

  if (canvas.width !== displayW || canvas.height !== displayH) {
    canvas.width = displayW;
    canvas.height = displayH;
  }
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (!detections || detections.length === 0) return;

  const intrinsicW = video.videoWidth || frameW || 1920;
  const intrinsicH = video.videoHeight || frameH || 1080;

  if (intrinsicW <= 0 || intrinsicH <= 0 || displayW <= 0 || displayH <= 0) return;

  const videoAspect = intrinsicW / intrinsicH;
  const displayAspect = displayW / displayH;

  let renderW = displayW;
  let renderH = displayH;
  let offsetX = 0;
  let offsetY = 0;

  if (displayAspect > videoAspect) {
    renderH = displayH;
    renderW = displayH * videoAspect;
    offsetX = (displayW - renderW) / 2;
    offsetY = 0;
  } else {
    renderW = displayW;
    renderH = displayW / videoAspect;
    offsetX = 0;
    offsetY = (displayH - renderH) / 2;
  }

  ctx.lineWidth = 2.5;
  ctx.font = "bold 13px sans-serif";

  for (const d of detections) {
    let rx1 = 0, ry1 = 0, rx2 = 0, ry2 = 0;
    let hasCoords = false;

    if (d.rel_box && Array.isArray(d.rel_box) && d.rel_box.length >= 4) {
      [rx1, ry1, rx2, ry2] = d.rel_box;
      hasCoords = true;
    } else if (d.box && Array.isArray(d.box) && d.box.length >= 4) {
      const [x1, y1, x2, y2] = d.box;
      if (x1 <= 1.0 && y1 <= 1.0 && x2 <= 1.0 && y2 <= 1.0 && (x2 > 0 || y2 > 0)) {
        rx1 = x1;
        ry1 = y1;
        rx2 = x2;
        ry2 = y2;
      } else {
        const baseW = frameW || intrinsicW;
        const baseH = frameH || intrinsicH;
        rx1 = baseW > 0 ? x1 / baseW : 0;
        ry1 = baseH > 0 ? y1 / baseH : 0;
        rx2 = baseW > 0 ? x2 / baseW : 0;
        ry2 = baseH > 0 ? y2 / baseH : 0;
      }
      hasCoords = true;
    }

    if (!hasCoords) continue;

    rx1 = Math.max(0, Math.min(1, rx1));
    ry1 = Math.max(0, Math.min(1, ry1));
    rx2 = Math.max(0, Math.min(1, rx2));
    ry2 = Math.max(0, Math.min(1, ry2));

    const bx = offsetX + rx1 * renderW;
    const by = offsetY + ry1 * renderH;
    const bw = Math.max(0, (rx2 - rx1) * renderW);
    const bh = Math.max(0, (ry2 - ry1) * renderH);

    if (bw <= 0 || bh <= 0) continue;

    const mainColor = getColorForClass(d.class_id, d.label);

    ctx.strokeStyle = mainColor;
    ctx.strokeRect(bx, by, bw, bh);

    const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
    const labelText = (d.label || ("class_" + d.class_id)) + (confStr ? " " + confStr : "");
    const textWidth = ctx.measureText(labelText).width + 8;
    const labelHeight = 18;

    ctx.fillStyle = mainColor;
    ctx.fillRect(bx, by - labelHeight >= 0 ? by - labelHeight : by, textWidth, labelHeight);

    ctx.fillStyle = "#ffffff";
    ctx.fillText(labelText, bx + 4, (by - labelHeight >= 0 ? by - labelHeight : by) + 13);
  }
}

export function renderDetectionList(listEl, detections) {
  if (!listEl) return;
  listEl.innerHTML = "";
  if (!detections || !detections.length) {
    listEl.innerHTML = '<li class="text-zinc-400">无目标</li>';
    return;
  }
  for (const d of detections) {
    const li = document.createElement("li");
    li.className =
      "flex items-center justify-between rounded border border-zinc-100 bg-zinc-50 px-3 py-2";
    const left = document.createElement("span");
    left.className = "font-medium text-zinc-800 flex items-center gap-1.5";

    const dot = document.createElement("span");
    dot.className = "w-2.5 h-2.5 rounded-full inline-block";
    dot.style.backgroundColor = getColorForClass(d.class_id, d.label);
    left.appendChild(dot);

    const text = document.createElement("span");
    text.textContent = d.label || ("class_" + d.class_id);
    left.appendChild(text);

    const right = document.createElement("span");
    right.className = "font-mono text-zinc-500 text-xs";
    const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
    let coordStr = "";
    if (d.rel_box && Array.isArray(d.rel_box)) {
      coordStr = "[" + d.rel_box.map((v) => (v * 100).toFixed(1) + "%").join(", ") + "]";
    } else if (d.box && Array.isArray(d.box)) {
      coordStr = "[" + d.box.join(",") + "]";
    }
    right.textContent = confStr + (coordStr ? "  " + coordStr : "");
    li.append(left, right);
    listEl.appendChild(li);
  }
}
```

webrtc_player.js

```javascript
import { drawDetections, renderDetectionList } from "./overlay_renderer";

export class WebRtcPlayer {
  constructor({
    streamId,
    url,
    videoEl,
    canvasEl,
    listEl,
    statusEl,
    countEl,
    rateEl,
    connectBtnEl,
  }) {
    this.streamId = streamId;
    this.url = url || "";
    this.videoEl = videoEl;
    this.canvasEl = canvasEl;
    this.listEl = listEl;
    this.statusEl = statusEl;
    this.countEl = countEl;
    this.rateEl = rateEl;
    this.connectBtnEl = connectBtnEl;

    this.pc = null;
    this.msgCount = 0;
    this.currentFps = 0;
    this.detectionQueue = [];
    this.renderLoopRunning = false;
    this.isConnected = false;

    this.initRateTimer();
  }

  initRateTimer() {
    this.rateInterval = setInterval(() => {
      this.currentFps = this.msgCount;
      if (this.rateEl) {
        this.rateEl.textContent = this.currentFps;
      }
      this.msgCount = 0;
    }, 1000);
  }

  setStatus(text, isOk) {
    if (this.statusEl) {
      this.statusEl.textContent = text;
      this.statusEl.className =
        "rounded-full px-2 py-0.5 font-medium transition-colors whitespace-nowrap " +
        (isOk ? "bg-green-100 text-green-700" : "bg-zinc-200 text-zinc-700");
    }

    if (this.connectBtnEl) {
      if (isOk) {
        this.connectBtnEl.textContent = "断开";
        this.connectBtnEl.className =
          "rounded bg-red-600 px-2.5 py-0.5 text-xs font-semibold text-white hover:bg-red-700 transition-colors cursor-pointer shadow-sm whitespace-nowrap";
      } else {
        this.connectBtnEl.textContent = "连接";
        this.connectBtnEl.className =
          "rounded bg-blue-600 px-2.5 py-0.5 text-xs font-semibold text-white hover:bg-blue-700 transition-colors cursor-pointer shadow-sm whitespace-nowrap";
      }
    }
  }

  waitIceComplete(conn) {
    return new Promise((resolve) => {
      if (conn.iceGatheringState === "complete") return resolve();
      const timer = setTimeout(resolve, 1200);
      conn.addEventListener("icegatheringstatechange", () => {
        if (conn.iceGatheringState === "complete") {
          clearTimeout(timer);
          resolve();
        }
      });
    });
  }

  startSyncRenderer() {
    if (!this.videoEl || this.renderLoopRunning) return;
    this.renderLoopRunning = true;

    const renderLoop = () => {
      if (!this.renderLoopRunning) return;

      if (this.detectionQueue.length > 0) {
        const bestMsg = this.detectionQueue[this.detectionQueue.length - 1];
        if (bestMsg) {
          const detections = bestMsg.detections || [];
          if (this.canvasEl && this.videoEl) {
            drawDetections(
              this.canvasEl,
              this.videoEl,
              detections,
              bestMsg.frame_width,
              bestMsg.frame_height
            );
          }
          if (this.listEl) {
            renderDetectionList(this.listEl, detections);
          }
          if (this.countEl) {
            this.countEl.textContent = detections.length;
          }
        }
      }

      if (this.videoEl && this.videoEl.requestVideoFrameCallback) {
        this.videoEl.requestVideoFrameCallback(renderLoop);
      } else {
        requestAnimationFrame(renderLoop);
      }
    };

    if (this.videoEl.requestVideoFrameCallback) {
      this.videoEl.requestVideoFrameCallback(renderLoop);
    } else {
      requestAnimationFrame(renderLoop);
    }
  }

  handleDataChannelMessage(ev) {
    this.msgCount++;
    try {
      const msg = JSON.parse(ev.data);
      if (msg.id && this.streamId && msg.id !== this.streamId) {
        return;
      }
      msg.localRecvTime = performance.now();
      this.detectionQueue.push(msg);
      if (this.detectionQueue.length > 30) {
        this.detectionQueue.shift();
      }

      if (!this.renderLoopRunning) {
        const detections = msg.detections || [];
        if (this.canvasEl && this.videoEl) {
          drawDetections(
            this.canvasEl,
            this.videoEl,
            detections,
            msg.frame_width,
            msg.frame_height
          );
        }
        if (this.listEl) {
          renderDetectionList(this.listEl, detections);
        }
        if (this.countEl) {
          this.countEl.textContent = detections.length;
        }
      }
    } catch (e) {
      console.warn(`[WebRtcPlayer:${this.streamId}] 解析 DataChannel 数据失败`, e);
    }
  }

  async connect() {
    let targetUrl = this.url ? this.url.trim() : "";
    if (!targetUrl) {
      const host = window.location.hostname || "127.0.0.1";
      targetUrl = `http://${host}:8181/${this.streamId}`;
    }
    if (!targetUrl.startsWith("http://") && !targetUrl.startsWith("https://")) {
      targetUrl = "http://" + targetUrl;
    }

    this.disconnect();
    this.setStatus("连接中…", false);

    try {
      this.pc = new RTCPeerConnection({
        iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
      });

      this.pc.addTransceiver("video", { direction: "recvonly" });

      if (this.videoEl) {
        this.pc.ontrack = (e) => {
          this.videoEl.srcObject = e.streams[0];
          this.videoEl.play().catch(() => {});
          this.setStatus("已连接", true);
          this.isConnected = true;
          this.startSyncRenderer();
        };
      }

      const dc = this.pc.createDataChannel("detection");
      dc.onmessage = (ev) => this.handleDataChannelMessage(ev);

      this.pc.ondatachannel = (e) => {
        e.channel.onmessage = (ev) => this.handleDataChannelMessage(ev);
      };

      this.pc.onconnectionstatechange = () => {
        const st = this.pc.connectionState;
        if (st === "connected") {
          this.setStatus("已连接", true);
          this.isConnected = true;
        } else if (st === "disconnected" || st === "failed" || st === "closed") {
          this.setStatus(st === "closed" ? "已断开" : "连接断开", false);
          this.isConnected = false;
          this.renderLoopRunning = false;
        }
      };

      const offer = await this.pc.createOffer();
      await this.pc.setLocalDescription(offer);
      await this.waitIceComplete(this.pc);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      const res = await fetch(targetUrl, {
        method: "POST",
        body: this.pc.localDescription.sdp,
        signal: controller.signal,
      }).catch((err) => {
        if (err.name === "AbortError") {
          throw new Error("信令响应超时 (4s): " + targetUrl);
        }
        throw new Error("连接失败: " + err.message);
      });
      clearTimeout(timeoutId);

      if (!res.ok) {
        const errText = await res.text();
        throw new Error("信令拒绝 (" + res.status + "): " + errText);
      }

      const answerSdp = await res.text();
      await this.pc.setRemoteDescription({ type: "answer", sdp: answerSdp });
      this.setStatus("已连接", true);
      this.isConnected = true;
    } catch (err) {
      this.setStatus("连接失败", false);
      this.isConnected = false;
      console.error(`[WebRtcPlayer:${this.streamId}] 连接异常:`, err);
    }
  }

  disconnect() {
    this.renderLoopRunning = false;
    this.isConnected = false;
    if (this.pc) {
      try {
        this.pc.close();
      } catch (e) {}
      this.pc = null;
    }
    if (this.videoEl) {
      this.videoEl.srcObject = null;
    }
    if (this.canvasEl) {
      const ctx = this.canvasEl.getContext("2d");
      if (ctx) ctx.clearRect(0, 0, this.canvasEl.width, this.canvasEl.height);
    }
    if (this.listEl) {
      this.listEl.innerHTML = '<li class="text-zinc-400">未连接</li>';
    }
    if (this.countEl) {
      this.countEl.textContent = "0";
    }
    this.setStatus("未连接", false);
  }

  toggleConnect() {
    if (this.isConnected) {
      this.disconnect();
    } else {
      this.connect();
    }
  }

  destroy() {
    if (this.rateInterval) clearInterval(this.rateInterval);
    this.disconnect();
  }
}

export class StreamCardController {
  constructor(cardEl) {
    this.cardEl = cardEl;
    this.streamId = cardEl.getAttribute("data-stream-id") || cardEl.id.replace("stream-card-", "");
    this.customUrl = cardEl.getAttribute("data-stream-url") || "";

    this.urlInputEl = cardEl.querySelector(`#url-input-${this.streamId}`);
    this.videoEl = cardEl.querySelector(`#video-${this.streamId}`);
    this.canvasEl = cardEl.querySelector(`#overlay-${this.streamId}`);
    this.listEl = cardEl.querySelector(`#det-list-${this.streamId}`);
    this.statusEl = cardEl.querySelector(`#status-${this.streamId}`);
    this.countEl = cardEl.querySelector(`#count-${this.streamId}`);
    this.rateEl = cardEl.querySelector(`#rate-${this.streamId}`);
    this.connectBtnEl = cardEl.querySelector(`#btn-connect-${this.streamId}`);
    this.fsBtnEl = cardEl.querySelector(`#btn-fs-${this.streamId}`);
    this.removeBtnEl = cardEl.querySelector(`#btn-remove-${this.streamId}`);
    this.videoWrapEl = cardEl.querySelector(`#video-wrap-${this.streamId}`);

    const host = window.location.hostname || "127.0.0.1";
    const resolvedUrl = (this.urlInputEl && this.urlInputEl.value.trim())
      ? this.urlInputEl.value.trim()
      : (this.customUrl || `http://${host}:8181/${this.streamId}`);

    if (this.urlInputEl && !this.urlInputEl.value.trim()) {
      this.urlInputEl.value = resolvedUrl;
    }

    this.player = new WebRtcPlayer({
      streamId: this.streamId,
      url: resolvedUrl,
      videoEl: this.videoEl,
      canvasEl: this.canvasEl,
      listEl: this.listEl,
      statusEl: this.statusEl,
      countEl: this.countEl,
      rateEl: this.rateEl,
      connectBtnEl: this.connectBtnEl,
    });

    this.bindEvents();
  }

  bindEvents() {
    if (this.connectBtnEl) {
      this.connectBtnEl.onclick = () => {
        if (this.urlInputEl && this.urlInputEl.value.trim()) {
          this.player.url = this.urlInputEl.value.trim();
        }
        this.player.toggleConnect();
      };
    }
    if (this.fsBtnEl && this.videoWrapEl) {
      this.fsBtnEl.onclick = () => {
        if (this.videoWrapEl.requestFullscreen) this.videoWrapEl.requestFullscreen();
      };
    }
  }

  connect() {
    if (this.urlInputEl && this.urlInputEl.value.trim()) {
      this.player.url = this.urlInputEl.value.trim();
    }
    return this.player.connect();
  }

  disconnect() {
    return this.player.disconnect();
  }

  destroy() {
    this.player.destroy();
    if (this.cardEl && this.cardEl.parentNode) {
      this.cardEl.parentNode.removeChild(this.cardEl);
    }
  }
}

export class StreamGridManager {
  constructor() {
    this.gridContainer = document.getElementById("stream-cards-grid");
    this.templateEl = document.getElementById("stream-card-template");
    this.controllers = new Map();
    this.counter = 0;

    this.initCards();
    this.bindGlobalButtons();
  }

  initCards() {
    if (!this.gridContainer) return;
    const cards = this.gridContainer.querySelectorAll(".stream-card");
    cards.forEach((cardEl) => {
      this.attachCard(cardEl);
    });
  }

  attachCard(cardEl) {
    const streamId = cardEl.getAttribute("data-stream-id") || cardEl.id.replace("stream-card-", "");
    if (this.controllers.has(streamId)) {
      return this.controllers.get(streamId);
    }

    const controller = new StreamCardController(cardEl);
    this.controllers.set(streamId, controller);

    if (controller.removeBtnEl) {
      controller.removeBtnEl.onclick = () => {
        controller.destroy();
        this.controllers.delete(streamId);
      };
    }
    return controller;
  }

  addCard(streamId = "") {
    this.counter++;
    const id = streamId.trim() || `stream_${this.counter}`;
    if (this.controllers.has(id)) {
      alert(`流 [${id}] 已存在`);
      return null;
    }

    if (this.templateEl && this.gridContainer) {
      const templateHtml = this.templateEl.innerHTML
        .replaceAll("__STREAM_ID__", id)
        .replaceAll("__STREAM_TITLE__", `通道: ${id}`);

      const wrapper = document.createElement("div");
      wrapper.innerHTML = templateHtml.trim();
      const newCardEl = wrapper.firstElementChild;

      if (newCardEl) {
        this.gridContainer.appendChild(newCardEl);
        return this.attachCard(newCardEl);
      }
    }
    return null;
  }

  connectAll() {
    for (const ctrl of this.controllers.values()) {
      ctrl.connect();
    }
  }

  disconnectAll() {
    for (const ctrl of this.controllers.values()) {
      ctrl.disconnect();
    }
  }

  bindGlobalButtons() {
    const btnAdd = document.getElementById("btn-add-stream");
    if (btnAdd) {
      btnAdd.onclick = () => {
        const name = prompt("请输入新流标识 (如 ccc 或 custom):", `stream_${this.controllers.size + 1}`);
        if (name && name.trim()) {
          this.addCard(name.trim());
        }
      };
    }

    const btnConnectAll = document.getElementById("btn-connect-all");
    if (btnConnectAll) {
      btnConnectAll.onclick = () => this.connectAll();
    }

    const btnDisconnectAll = document.getElementById("btn-disconnect-all");
    if (btnDisconnectAll) {
      btnDisconnectAll.onclick = () => this.disconnectAll();
    }
  }
}

let globalGridManager = null;

export function initWebRtcUI() {
  if (!globalGridManager) {
    globalGridManager = new StreamGridManager();
  }
  return globalGridManager;
}
```

app.js

```javascript
........................
........................
import { initWebRtcUI } from "./webrtc_player"

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initWebRtcUI)
} else {
  initWebRtcUI()
}
window.addEventListener("phx:page-loading-stop", initWebRtcUI)
```

player_component.ex

```elixir
defmodule WebWeb.PlayerComponent do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :default_url, :string, default: ""
  attr :removable, :boolean, default: true

  def stream_card(assigns) do
    ~H"""
    <div
      id={"stream-card-" <> @id}
      class="stream-card flex flex-col rounded-xl border border-zinc-200 bg-white p-3 shadow-sm hover:shadow transition-shadow"
      data-stream-id={@id}
      data-stream-url={@default_url}
    >
      <div class="flex flex-wrap items-center justify-between gap-2 pb-2.5 mb-2.5 border-b border-zinc-100">
        <div class="flex flex-1 items-center gap-1.5 min-w-[240px]">
          <label class="text-xs font-semibold text-zinc-600 whitespace-nowrap">URI:</label>
          <input
            type="text"
            id={"url-input-" <> @id}
            value={@default_url}
            placeholder={"http://127.0.0.1:8181/" <> @id}
            class="flex-1 rounded border border-zinc-300 px-2 py-1 text-xs font-mono text-zinc-800 bg-zinc-50 shadow-inner focus:border-blue-500 focus:outline-none"
          />
          <button
            type="button"
            id={"btn-connect-" <> @id}
            class="rounded bg-blue-600 px-3 py-1 text-xs font-semibold text-white hover:bg-blue-700 transition-colors cursor-pointer shadow-sm whitespace-nowrap"
          >
            连接
          </button>
        </div>

        <div class="flex items-center gap-2 text-xs">
          <span id={"status-" <> @id} class="rounded-full bg-zinc-200 px-2 py-0.5 font-medium text-zinc-700 transition-colors whitespace-nowrap">
            未连接
          </span>
          <span class="text-zinc-500 whitespace-nowrap">目标: <b id={"count-" <> @id} class="font-mono text-green-600">0</b></span>
          <span class="text-zinc-500 whitespace-nowrap">帧率: <b id={"rate-" <> @id} class="font-mono text-blue-600">0</b></span>
          <button
            type="button"
            id={"btn-fs-" <> @id}
            class="rounded border border-zinc-200 px-2 py-0.5 text-zinc-600 hover:bg-zinc-100 cursor-pointer whitespace-nowrap"
            title="全屏"
          >
            全屏
          </button>
          <button
            :if={@removable}
            type="button"
            id={"btn-remove-" <> @id}
            class="rounded border border-zinc-200 px-1.5 py-0.5 text-zinc-400 hover:bg-red-50 hover:text-red-600 cursor-pointer font-bold"
            title="移除此流窗口"
          >
            ✕
          </button>
        </div>
      </div>

      <div id={"video-wrap-" <> @id} class="relative w-full aspect-video overflow-hidden rounded-lg bg-black flex items-center justify-center">
        <video id={"video-" <> @id} autoplay playsinline muted class="w-full h-full object-contain block"></video>
        <canvas id={"overlay-" <> @id} class="pointer-events-none absolute inset-0 w-full h-full" style="z-index: 30; pointer-events: none;"></canvas>
      </div>

      <details class="mt-2 text-xs text-zinc-600">
        <summary class="cursor-pointer font-medium text-zinc-500 hover:text-zinc-700 select-none">
          实时检测目标列表
        </summary>
        <div class="mt-1.5 max-h-32 overflow-y-auto pr-1">
          <ul id={"det-list-" <> @id} class="space-y-1">
            <li class="text-zinc-400">暂无目标</li>
          </ul>
        </div>
      </details>
    </div>
    """
  end
end
```

home.html.heex

```html
<div class="w-full min-h-screen px-4 sm:px-6 lg:px-8 py-5 bg-zinc-100">
  <div class="mb-4 flex flex-wrap items-center justify-between gap-3 bg-white p-3.5 rounded-xl border border-zinc-200 shadow-sm">
    <div class="flex items-center gap-2">
      <div class="w-2.5 h-2.5 rounded-full bg-blue-600 animate-pulse"></div>
      <h1 class="text-sm sm:text-base font-bold text-zinc-800">视频识别检测</h1>
    </div>

    <div class="flex flex-wrap items-center gap-2">
      <button
        type="button"
        id="btn-add-stream"
        class="rounded bg-zinc-800 px-3 py-1.5 text-xs font-semibold text-white hover:bg-zinc-700 transition-colors cursor-pointer shadow-sm flex items-center gap-1"
      >
        <span>+</span> 添加流窗口
      </button>
      <button
        type="button"
        id="btn-connect-all"
        class="rounded bg-blue-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-blue-700 transition-colors cursor-pointer shadow-sm"
      >
        全部连接
      </button>
      <button
        type="button"
        id="btn-disconnect-all"
        class="rounded border border-zinc-300 bg-white px-3 py-1.5 text-xs font-semibold text-zinc-700 hover:bg-zinc-100 transition-colors cursor-pointer shadow-sm"
      >
        全部断开
      </button>
    </div>
  </div>

  <div id="stream-cards-grid" class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <WebWeb.PlayerComponent.stream_card id="aaa" title="通道 1: aaa" />
    <WebWeb.PlayerComponent.stream_card id="bbb" title="通道 2: bbb" />
  </div>

  <template id="stream-card-template">
    <WebWeb.PlayerComponent.stream_card id="__STREAM_ID__" title="__STREAM_TITLE__" />
  </template>
</div>
```
