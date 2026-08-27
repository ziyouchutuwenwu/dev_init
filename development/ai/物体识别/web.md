# web

## 说明

对接 rust 转出来的 webrtc

## 代码

overlay_renderer.js

```javascript
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

    ctx.strokeStyle = "#22c55e";
    ctx.strokeRect(bx, by, bw, bh);

    const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
    const labelText = (d.label || ("class_" + d.class_id)) + (confStr ? " " + confStr : "");
    const textWidth = ctx.measureText(labelText).width + 8;
    const labelHeight = 18;

    ctx.fillStyle = "rgba(34, 197, 94, 0.88)";
    ctx.fillRect(bx, by, textWidth, labelHeight);

    ctx.fillStyle = "#ffffff";
    ctx.fillText(labelText, bx + 4, by + 13);
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
    left.className = "font-medium text-zinc-800";
    left.textContent = d.label || ("class_" + d.class_id);
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
  constructor(options = {}) {
    this.videoEl = options.videoEl || document.getElementById("video");
    this.canvasEl = options.canvasEl || document.getElementById("overlay");
    this.listEl = options.listEl || document.getElementById("det-list");
    this.statusEl = options.statusEl || document.getElementById("status");
    this.rateEl = options.rateEl || document.getElementById("det-rate");
    this.inputEl = options.inputEl || document.getElementById("signaling-url-input");
    this.connectBtn = options.connectBtn || document.getElementById("connect-btn");

    this.pc = null;
    this.msgCount = 0;
    this.detectionQueue = [];
    this.renderLoopRunning = false;

    this.initRateTimer();
  }

  initRateTimer() {
    setInterval(() => {
      if (this.rateEl) {
        this.rateEl.textContent = this.msgCount;
      }
      this.msgCount = 0;
    }, 1000);
  }

  setStatus(text, ok) {
    if (!this.statusEl) return;
    this.statusEl.textContent = text;
    this.statusEl.className =
      "rounded-full px-3 py-1 text-sm transition-colors font-medium " +
      (ok ? "bg-green-100 text-green-700" : "bg-zinc-200 text-zinc-700");
  }

  setSignalingUrl(url) {
    if (this.inputEl) {
      this.inputEl.value = url;
    }
  }

  getSignalingUrl() {
    const defaultUrl =
      "http://" + (location.hostname || "127.0.0.1") + ":8181/offer";
    if (this.inputEl && this.inputEl.value.trim()) {
      return this.inputEl.value.trim();
    }
    return defaultUrl;
  }

  waitIceComplete(conn) {
    return new Promise((resolve) => {
      if (conn.iceGatheringState === "complete") return resolve();
      const timer = setTimeout(resolve, 1000);
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
          drawDetections(
            this.canvasEl,
            this.videoEl,
            bestMsg.detections || [],
            bestMsg.frame_width,
            bestMsg.frame_height
          );
          renderDetectionList(this.listEl, bestMsg.detections || []);
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
      msg.localRecvTime = performance.now();
      this.detectionQueue.push(msg);
      if (this.detectionQueue.length > 30) {
        this.detectionQueue.shift();
      }

      if (!this.renderLoopRunning) {
        drawDetections(
          this.canvasEl,
          this.videoEl,
          msg.detections || [],
          msg.frame_width,
          msg.frame_height
        );
        renderDetectionList(this.listEl, msg.detections || []);
      }
    } catch (e) {
      console.warn("[WebRTC] 解析 DataChannel 消息失败", e);
    }
  }

  async connect() {
    console.log("[WebRTC] 开始发起连接...");
    if (this.pc) {
      try {
        this.pc.close();
      } catch (e) {}
      this.pc = null;
    }

    this.detectionQueue = [];
    const signalingUrl = this.getSignalingUrl();

    if (this.connectBtn) this.connectBtn.disabled = true;
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
          this.startSyncRenderer();
        };
      }

      const dc = this.pc.createDataChannel("detection");
      dc.onmessage = (ev) => this.handleDataChannelMessage(ev);
      dc.onopen = () => {
        console.log("[WebRTC DataChannel] 已建立，开始接收目标检测数据");
      };

      this.pc.ondatachannel = (e) => {
        e.channel.onmessage = (ev) => this.handleDataChannelMessage(ev);
      };

      this.pc.onconnectionstatechange = () => {
        console.log("[WebRTC State]", this.pc.connectionState);
        if (this.pc.connectionState === "connected") {
          this.setStatus("已连接", true);
          if (this.connectBtn) this.connectBtn.disabled = false;
        } else if (
          this.pc.connectionState === "disconnected" ||
          this.pc.connectionState === "failed"
        ) {
          this.setStatus("连接断开: " + this.pc.connectionState, false);
          if (this.connectBtn) this.connectBtn.disabled = false;
          this.renderLoopRunning = false;
        }
      };

      const offer = await this.pc.createOffer();
      await this.pc.setLocalDescription(offer);
      await this.waitIceComplete(this.pc);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      const res = await fetch(signalingUrl, {
        method: "POST",
        body: this.pc.localDescription.sdp,
        signal: controller.signal,
      }).catch((err) => {
        if (err.name === "AbortError") {
          throw new Error("连接超时 (4秒)，目标信令服务未响应: " + signalingUrl);
        }
        throw new Error(
          "无法连接到信令服务 (" + err.message + "): " + signalingUrl
        );
      });
      clearTimeout(timeoutId);

      if (!res.ok) throw new Error("信令失败: " + (await res.text()));
      const answerSdp = await res.text();
      await this.pc.setRemoteDescription({ type: "answer", sdp: answerSdp });
      this.setStatus("已连接 (实时流 + 目标检测)", true);
      if (this.connectBtn) this.connectBtn.disabled = false;
    } catch (err) {
      this.setStatus("连接失败", false);
      if (this.connectBtn) this.connectBtn.disabled = false;
      console.error(err);
      alert(err.message);
    }
  }
}

let globalPlayer = null;

export function getPlayer() {
  if (!globalPlayer) {
    globalPlayer = new WebRtcPlayer();
  }
  return globalPlayer;
}

export function initWebRtcUI() {
  const player = getPlayer();
  const inputEl = document.getElementById("signaling-url-input");
  if (inputEl && !inputEl.value) {
    inputEl.value = "http://192.168.88.100:8181/offer";
  }

  const btn = document.getElementById("connect-btn");
  if (btn) {
    btn.onclick = () => player.connect();
  }

  const btnBoard = document.getElementById("btn-preset-board");
  if (btnBoard) {
    btnBoard.onclick = () =>
      player.setSignalingUrl("http://192.168.88.100:8181/offer");
  }

  const btnLocal = document.getElementById("btn-preset-local");
  if (btnLocal) {
    btnLocal.onclick = () =>
      player.setSignalingUrl(
        "http://" + (location.hostname || "127.0.0.1") + ":8181/offer"
      );
  }

  window.setSignalingUrl = (url) => player.setSignalingUrl(url);
  window.connectWebRTC = () => player.connect();

  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get("autoconnect") === "1") {
    setTimeout(() => player.connect(), 300);
  }
}
```

app.js

```javascript
......
......
import { initWebRtcUI } from "./webrtc_player"

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initWebRtcUI)
} else {
  initWebRtcUI()
}
window.addEventListener("phx:page-loading-stop", initWebRtcUI)
```

home.html.heex

```html
<div class="w-full min-h-screen px-4 sm:px-6 lg:px-8 py-4">
  <header class="mb-4 flex flex-wrap items-center justify-between gap-3 border-b border-zinc-200 pb-3">
    <div class="flex flex-wrap items-center gap-2">
      <div class="flex items-center gap-1.5">
        <label for="signaling-url-input" class="text-xs font-medium text-zinc-600">地址:</label>
        <input
          type="text"
          id="signaling-url-input"
          value="http://192.168.88.100:8181/offer"
          class="rounded border border-zinc-300 px-2 py-1 text-xs font-mono text-zinc-800 w-64 sm:w-80 shadow-sm focus:border-blue-500 focus:outline-none"
          placeholder="http://192.168.88.100:8181/offer"
        />
      </div>
      <button
        type="button"
        id="btn-preset-board"
        onclick="window.setSignalingUrl && window.setSignalingUrl('http://192.168.88.100:8181/offer')"
        class="rounded border border-zinc-300 bg-white px-2.5 py-1 text-xs font-medium text-zinc-700 hover:bg-zinc-100 cursor-pointer"
      >
        开发板 (100)
      </button>
      <button
        type="button"
        id="btn-preset-local"
        onclick="window.setSignalingUrl && window.setSignalingUrl('http://127.0.0.1:8181/offer')"
        class="rounded border border-zinc-300 bg-white px-2.5 py-1 text-xs font-medium text-zinc-700 hover:bg-zinc-100 cursor-pointer"
      >
        本机 (localhost)
      </button>
      <span
        id="status"
        class="rounded-full bg-zinc-200 px-3 py-1 text-sm text-zinc-700 transition-colors font-medium"
      >
        未连接
      </span>
      <button
        id="connect-btn"
        onclick="window.connectWebRTC && window.connectWebRTC()"
        class="rounded bg-blue-600 px-4 py-1.5 text-sm font-semibold text-white transition-colors hover:bg-blue-700 disabled:opacity-50 cursor-pointer shadow-sm"
      >
        连接
      </button>
    </div>

    <div class="flex items-center gap-4 text-xs text-zinc-600">
      <span>检测帧率: <span id="det-rate" class="font-mono font-semibold text-blue-600 text-sm">0</span> 帧/秒</span>
      <button
        type="button"
        onclick="document.getElementById('video-container').requestFullscreen && document.getElementById('video-container').requestFullscreen()"
        class="rounded border border-zinc-300 bg-white px-2.5 py-1 text-xs font-medium text-zinc-700 hover:bg-zinc-100 cursor-pointer"
      >
        全屏查看
      </button>
    </div>
  </header>

  <div class="grid grid-cols-1 gap-4 lg:grid-cols-4 xl:grid-cols-5">
    <div class="lg:col-span-3 xl:col-span-4 flex flex-col">
      <div id="video-container" class="relative w-full overflow-hidden rounded-xl bg-black shadow-lg aspect-video flex items-center justify-center">
        <video id="video" autoplay playsinline muted class="w-full h-full object-contain block"></video>
        <canvas id="overlay" class="pointer-events-none absolute inset-0 w-full h-full" style="z-index: 30; pointer-events: none;"></canvas>
      </div>
    </div>

    <div class="lg:col-span-1 xl:col-span-1 flex flex-col rounded-xl border border-zinc-200 bg-white p-4 shadow-sm h-full max-h-[85vh]">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-base font-semibold text-zinc-800">实时检测目标</h2>
      </div>
      <div class="flex-1 overflow-y-auto pr-1">
        <ul id="det-list" class="space-y-2 text-xs">
          <li class="text-zinc-400">等待数据…</li>
        </ul>
      </div>
    </div>
  </div>
</div>
```
