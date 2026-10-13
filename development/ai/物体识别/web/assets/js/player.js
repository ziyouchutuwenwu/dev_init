import { drawDetections, renderDetectionList, clientToRelCoords } from "./ui_render";

function showGlobalToast(msg, type = "info") {
  const toast = document.getElementById("global-feedback-toast") || document.getElementById("stream-config-feedback");
  if (!toast) return;

  const baseClasses =
    "fixed top-6 left-1/2 -translate-x-1/2 z-50 px-5 py-2.5 rounded-xl shadow-lg border text-xs font-semibold tracking-wide transition-all pointer-events-none ";
  const styleClasses =
    type === "success"
      ? "bg-white text-emerald-700 border-emerald-200 shadow-emerald-500/10"
      : type === "error"
      ? "bg-white text-red-700 border-red-200 shadow-red-500/10"
      : "bg-white text-blue-700 border-blue-200 shadow-blue-500/10";

  toast.className = baseClasses + styleClasses;
  toast.textContent = msg;
  toast.classList.remove("hidden");

  if (window._globalToastTimer) clearTimeout(window._globalToastTimer);
  window._globalToastTimer = setTimeout(() => {
    toast.classList.add("hidden");
  }, 2000);
}

window.switchOrOpenTab = function (url, targetName) {
  try {
    const existing = window.open("", targetName);
    if (existing && existing.location && existing.location.pathname && existing.location.pathname !== "blank") {
      existing.focus();
      return false;
    } else if (existing) {
      existing.location.href = url;
      existing.focus();
      return false;
    }
  } catch (e) {}
  return true;
};

export class Player {
  constructor({
    streamId,
    url,
    videoEl,
    canvasEl,
    connectBtnEl,
    statusEl,
    countEl,
    rateEl,
  }) {
    this.streamId = streamId;
    this.url = url || "";

    this.videoEl = null;
    this.canvasEl = null;
    this.listEl = null;
    this.statusEl = null;
    this.countEl = null;
    this.rateEl = null;
    this.connectBtnEl = null;

    this._zoneConfig = null;
    this.hasUnsavedChanges = false;
    this.drawingState = { active: false, mode: null, isDragging: false, p1: null, p2: null };

    this.pc = null;
    this.dc = null;
    this.msgCount = 0;
    this.currentFps = 0;
    this.detectionQueue = [];
    this.renderLoopRunning = false;
    this.isConnected = false;
    this.manualDisconnect = false;
    this.reconnectTimer = null;
    this.lastFrameIdx = null;
    this.lastDataChannelRecvTime = 0;

    this.mediaStream = null;
    this.rateInterval = null;

    this._cardEl = null;
    this._onGlobalMouseMove = null;
    this._onGlobalMouseUp = null;
    this._onGlobalKeyDown = null;

    this.bindElements({ videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl });
    this.connect();
  }

  get zoneConfig() {
    return this._zoneConfig;
  }

  set zoneConfig(cfg) {
    this._zoneConfig = cfg;
    if (!this.renderLoopRunning) {
      this.renderOverlay();
    }
  }

  bindElements({ videoEl, canvasEl, connectBtnEl, statusEl, countEl, rateEl }) {
    this.videoEl = videoEl;
    this.canvasEl = canvasEl;
    this.connectBtnEl = connectBtnEl;
    this.statusEl = statusEl;
    this.countEl = countEl;
    this.rateEl = rateEl;

    const cardEl = this.videoEl?.closest(".stream-card") || this.canvasEl?.closest(".stream-card");
    this._cardEl = cardEl;
    this.listEl = cardEl?.querySelector(`#det-list-${this.streamId}`) || null;

    if (this.videoEl) {
      this.videoEl.muted = true;
      this.videoEl.autoplay = true;
      this.videoEl.playsInline = true;
      this.videoEl.setAttribute("autoplay", "");
      this.videoEl.setAttribute("muted", "");
      this.videoEl.setAttribute("playsinline", "");
    }

    this.setStatus(this.isConnected ? "已连接" : "未连接", this.isConnected);

    if (this.connectBtnEl) {
      this.connectBtnEl.onclick = () => {
        const inputVal = cardEl?.querySelector(`#url-input-${this.streamId}`)?.value?.trim();
        if (inputVal) {
          this.url = this.resolveUrl(inputVal);
        }
        this.toggleConnect();
      };
    }

    const fsBtn = cardEl?.querySelector(`#btn-fs-${this.streamId}`);
    const videoWrap = cardEl?.querySelector(`#video-wrap-${this.streamId}`);
    if (fsBtn && videoWrap) {
      fsBtn.onclick = () => {
        if (videoWrap.requestFullscreen) videoWrap.requestFullscreen();
      };
    }

    this.bindCalibrationEvents(cardEl);

    if (!this._zoneConfig && cardEl?.dataset.zoneConfig) {
      try {
        const localCfg = JSON.parse(cardEl.dataset.zoneConfig);
        if (localCfg) this._zoneConfig = localCfg;
      } catch (e) {}
    }

    if (!this._zoneConfig) {
      fetch(`/api/zone/${this.streamId}`)
        .then((res) => (res.ok ? res.json() : null))
        .then((data) => {
          if (data && data.config) {
            this.zoneConfig = data.config;
          }
        })
        .catch(() => {});
    }

    if (this.isConnected && this.mediaStream && this.videoEl) {
      this.videoEl.srcObject = this.mediaStream;
      this.videoEl.muted = true;
      this.videoEl.autoplay = true;
      this.videoEl.playsInline = true;
      this.videoEl.play().catch(() => {});
      this.renderLoopRunning = false;
      this.startSyncRenderer();
    }
  }

  unbindElements() {
    this.renderLoopRunning = false;
    this.unbindCalibrationEvents();
    if (this.videoEl) {
      this.videoEl.srcObject = null;
      this.videoEl = null;
    }
    if (this.canvasEl) {
      const ctx = this.canvasEl.getContext("2d");
      if (ctx) ctx.clearRect(0, 0, this.canvasEl.width, this.canvasEl.height);
      this.canvasEl = null;
    }
    this.connectBtnEl = null;
    this.statusEl = null;
    this.countEl = null;
    this.rateEl = null;
    this.listEl = null;
    this._cardEl = null;
  }

  updateUrl(newUrl) {
    if (newUrl && this.url !== newUrl) {
      this.url = newUrl;
      if (this.isConnected) {
        this.connect();
      }
    }
  }

  resolveUrl(inputVal) {
    if (!inputVal) return this.url;
    if (inputVal.startsWith("http://") || inputVal.startsWith("https://")) {
      return inputVal;
    }
    let base = "";
    const grid = document.getElementById("stream-cards-grid");
    if (grid && grid.getAttribute("data-gateway-url")) {
      base = grid.getAttribute("data-gateway-url").trim().replace(/\/+$/, "");
    }
    return base ? `${base}/${inputVal}` : inputVal;
  }

  initRateTimer() {
    if (this.rateInterval) clearInterval(this.rateInterval);
    let lastFramesDecoded = 0;
    let lastTimestamp = 0;

    this.rateInterval = setInterval(async () => {
      let fps = 0;
      if (this.pc && this.isConnected) {
        try {
          const stats = await this.pc.getStats();
          for (const report of stats.values()) {
            if (report.type === "inbound-rtp" && report.kind === "video") {
              const currentFrames = report.framesDecoded || 0;
              const currentTime = report.timestamp || 0;
              if (lastTimestamp > 0 && currentTime > lastTimestamp) {
                const deltaFrames = currentFrames - lastFramesDecoded;
                const deltaTimeSec = (currentTime - lastTimestamp) / 1000;
                if (deltaTimeSec > 0 && deltaFrames >= 0) {
                  fps = Math.round(deltaFrames / deltaTimeSec);
                }
              }
              lastFramesDecoded = currentFrames;
              lastTimestamp = currentTime;
              break;
            }
          }
        } catch (e) {}
      } else {
        lastFramesDecoded = 0;
        lastTimestamp = 0;
      }

      this.currentFps = fps;
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

  renderOverlay() {
    if (!this.canvasEl) return;
    try {
      if (this.detectionQueue.length > 0) {
        const bestMsg = this.detectionQueue[this.detectionQueue.length - 1];
        if (bestMsg) {
          const now = performance.now();
          const isStale = (now - (bestMsg.localRecvTime || 0)) > 3000;
          const detections = isStale ? [] : (bestMsg.detections || []);
          drawDetections(
            this.canvasEl,
            this.videoEl,
            detections,
            bestMsg.frame_width || 1920,
            bestMsg.frame_height || 1080,
            this.zoneConfig,
            this.drawingState
          );
          return;
        }
      }
      drawDetections(
        this.canvasEl,
        this.videoEl,
        [],
        1920,
        1080,
        this.zoneConfig,
        this.drawingState
      );
    } catch (err) {}
  }

  startSyncRenderer() {
    if (!this.videoEl || this.renderLoopRunning) return;
    this.renderLoopRunning = true;

    const renderLoop = () => {
      if (!this.renderLoopRunning || !this.videoEl) {
        this.renderLoopRunning = false;
        return;
      }

      try {
        this.renderOverlay();
      } catch (err) {
      } finally {
        if (this.renderLoopRunning && this.videoEl) {
          if (this.videoEl.requestVideoFrameCallback) {
            this.videoEl.requestVideoFrameCallback(renderLoop);
          } else {
            requestAnimationFrame(renderLoop);
          }
        } else {
          this.renderLoopRunning = false;
        }
      }
    };

    if (this.videoEl.requestVideoFrameCallback) {
      this.videoEl.requestVideoFrameCallback(renderLoop);
    } else {
      requestAnimationFrame(renderLoop);
    }
  }

  wakeUp() {
    if (!this.isConnected) return;
    if (this.videoEl) {
      this.videoEl.muted = true;
      if (this.videoEl.paused) {
        this.videoEl.play().catch(() => {});
      }
    }
    try {
      this.renderOverlay();
    } catch (e) {}
    this.renderLoopRunning = false;
    this.startSyncRenderer();
  }

  handleDataChannelMessage(ev) {
    this.msgCount++;
    const now = performance.now();
    const timeSinceLastRecv = now - (this.lastDataChannelRecvTime || 0);
    this.lastDataChannelRecvTime = now;
    try {
      const msg = JSON.parse(ev.data);
      if (msg.id && this.streamId && msg.id !== this.streamId) {
        return;
      }
      if (msg.type === "heartbeat" || msg.type === "ping") {
        return;
      }

      if (msg.zone_config && !this.drawingState.active && !this.hasUnsavedChanges) {
        this._zoneConfig = msg.zone_config;
      }

      if (!Array.isArray(msg.detections)) {
        return;
      }

      if (msg.frame_idx !== undefined && msg.frame_idx !== null) {
        if (this.lastFrameIdx !== null && msg.frame_idx < this.lastFrameIdx) {
          if (this.lastFrameIdx - msg.frame_idx > 10 || timeSinceLastRecv > 500) {
            this.lastFrameIdx = msg.frame_idx;
          } else {
            return;
          }
        } else {
          this.lastFrameIdx = msg.frame_idx;
        }
      }

      msg.localRecvTime = performance.now();
      this.detectionQueue.push(msg);
      if (this.detectionQueue.length > 10) {
        this.detectionQueue.shift();
      }

      if (this.listEl) {
        renderDetectionList(this.listEl, msg.detections);
      }
      if (this.countEl) {
        this.countEl.textContent = msg.detections.length;
      }

      if (!this.renderLoopRunning) {
        if (this.canvasEl && this.videoEl) {
          drawDetections(
            this.canvasEl,
            this.videoEl,
            msg.detections,
            msg.frame_width,
            msg.frame_height,
            this.zoneConfig,
            this.drawingState
          );
        }
      }
    } catch (e) {}
  }

  bindDataChannel(dc) {
    if (!dc) return;
    this.dc = dc;
    dc.onmessage = (ev) => this.handleDataChannelMessage(ev);
    dc.onerror = () => {};
    dc.onclose = () => {
      if (this.isConnected && !this.manualDisconnect) {
        setTimeout(() => this.connect(), 1000);
      }
    };
  }

  async connect() {
    let targetUrl = this.url ? this.url.trim() : "";
    if (!targetUrl) {
      targetUrl = `http://192.168.88.100:8181/${this.streamId}`;
    }
    if (!targetUrl.startsWith("http://") && !targetUrl.startsWith("https://")) {
      targetUrl = "http://" + targetUrl;
    }

    this.disconnect();
    this.manualDisconnect = false;
    this.setStatus("连接中…", false);
    this.lastDataChannelRecvTime = performance.now();
    this.lastFrameIdx = null;
    this.initRateTimer();

    try {
      this.pc = new RTCPeerConnection({
        iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
      });

      this.pc.addTransceiver("video", { direction: "recvonly" });

      this.pc.ontrack = (e) => {
        this.mediaStream = e.streams[0];
        if (this.videoEl) {
          this.videoEl.srcObject = e.streams[0];
          this.videoEl.muted = true;
          this.videoEl.autoplay = true;
          this.videoEl.playsInline = true;
          this.videoEl.play().catch(() => {});
          this.startSyncRenderer();
        }
        this.setStatus("已连接", true);
        this.isConnected = true;
      };

      const dc = this.pc.createDataChannel("detection", {
        ordered: false,
      });
      this.bindDataChannel(dc);

      this.pc.ondatachannel = (e) => {
        this.bindDataChannel(e.channel);
      };

      this.pc.onconnectionstatechange = () => {
        const st = this.pc.connectionState;
        if (st === "connected") {
          this.setStatus("已连接", true);
          this.isConnected = true;
        } else if (st === "disconnected" || st === "failed") {
          this.setStatus("连接断开", false);
          this.isConnected = false;
          this.renderLoopRunning = false;
          if (!this.manualDisconnect && !this.reconnectTimer) {
            this.reconnectTimer = setTimeout(() => {
              this.reconnectTimer = null;
              if (!this.isConnected && !this.manualDisconnect) {
                this.connect();
              }
            }, 3000);
          }
        } else if (st === "closed") {
          this.setStatus("已断开", false);
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
      console.error(`[player:${this.streamId}] 连接异常:`, err);
      if (!this.manualDisconnect && !this.reconnectTimer) {
        this.reconnectTimer = setTimeout(() => {
          this.reconnectTimer = null;
          if (!this.isConnected && !this.manualDisconnect) {
            this.connect();
          }
        }, 5000);
      }
    }
  }

  disconnect() {
    this.manualDisconnect = true;
    if (this.rateInterval) {
      clearInterval(this.rateInterval);
      this.rateInterval = null;
    }
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.renderLoopRunning = false;
    this.isConnected = false;
    this.detectionQueue = [];
    this.lastFrameIdx = null;

    if (this.dc) {
      try {
        this.dc.close();
      } catch (e) {}
      this.dc = null;
    }
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
    if (this.rateEl) {
      this.rateEl.textContent = "0";
    }
    this.mediaStream = null;
    this.currentFps = 0;
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
    if (window._players) {
      window._players.delete(this.streamId);
    }
    if (this.rateInterval) {
      clearInterval(this.rateInterval);
      this.rateInterval = null;
    }
    this.unbindElements();
    this.disconnect();
  }

  bindCalibrationEvents(cardEl) {
    this.unbindCalibrationEvents();
    if (!cardEl) return;

    const btnDrawRoi = cardEl.querySelector(`#btn-draw-roi-${this.streamId}`);
    const btnResetZone = cardEl.querySelector(`#btn-reset-zone-${this.streamId}`);
    const btnSaveZone = cardEl.querySelector(`#btn-save-zone-${this.streamId}`);

    if (btnDrawRoi) {
      btnDrawRoi.onclick = () => {
        if (this.drawingState.active) {
          this.cancelDrawing();
        } else {
          this.startDrawing("roi");
        }
      };
    }

    if (btnResetZone) {
      btnResetZone.onclick = () => this.resetZoneToDefault();
    }

    if (btnSaveZone) {
      btnSaveZone.onclick = () => this.saveZoneConfig();
    }

    if (this.canvasEl) {
      this._onGlobalMouseMove = (e) => {
        if (!this.drawingState.active || !this.drawingState.isDragging || !this.videoEl || !this.canvasEl) return;
        e.preventDefault();
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.drawingState.p2 = pt;
        this.renderOverlay();
      };

      this._onGlobalMouseUp = (e) => {
        if (!this.drawingState.active || !this.drawingState.isDragging || !this.videoEl || !this.canvasEl) return;
        this.drawingState.isDragging = false;
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.drawingState.p2 = pt;

        const p1 = this.drawingState.p1;
        const p2 = this.drawingState.p2;

        if (p1 && p2) {
          const dx = Math.abs(p2[0] - p1[0]);
          const dy = Math.abs(p2[1] - p1[1]);

          if (dx >= 0.02 && dy >= 0.02) {
            const x1 = Math.min(p1[0], p2[0]);
            const y1 = Math.min(p1[1], p2[1]);
            const x2 = Math.max(p1[0], p2[0]);
            const y2 = Math.max(p1[1], p2[1]);
            const boxRect = [x1, y1, x2, y2];

            if (!this.zoneConfig) {
              this._zoneConfig = {
                enabled: true,
                target_classes: [],
              };
            }

            this.zoneConfig.trigger_box = boxRect;
            this.zoneConfig.roi = {
              type: "rect",
              coords: boxRect,
            };
            this.zoneConfig._hasUnsaved = true;
            this.hasUnsavedChanges = true;

            this.setSaveButtonAlert(true);
          }
        }

        this.cancelDrawing(true);
        this.renderOverlay();
      };

      this._onGlobalKeyDown = (e) => {
        if (e.key === "Escape" && this.drawingState.active) {
          this.cancelDrawing();
        }
      };

      this.canvasEl.onmousedown = (e) => {
        if (!this.drawingState.active || !this.videoEl || !this.canvasEl) return;
        e.preventDefault();
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.drawingState.p1 = pt;
        this.drawingState.p2 = pt;
        this.drawingState.isDragging = true;
        this.renderOverlay();
      };

      window.addEventListener("mousemove", this._onGlobalMouseMove);
      window.addEventListener("mouseup", this._onGlobalMouseUp);
      window.addEventListener("keydown", this._onGlobalKeyDown);
    }
  }

  unbindCalibrationEvents() {
    if (this._onGlobalMouseMove) {
      window.removeEventListener("mousemove", this._onGlobalMouseMove);
      this._onGlobalMouseMove = null;
    }
    if (this._onGlobalMouseUp) {
      window.removeEventListener("mouseup", this._onGlobalMouseUp);
      this._onGlobalMouseUp = null;
    }
    if (this._onGlobalKeyDown) {
      window.removeEventListener("keydown", this._onGlobalKeyDown);
      this._onGlobalKeyDown = null;
    }
  }

  startDrawing(mode) {
    this.drawingState.active = true;
    this.drawingState.mode = mode || "trigger_box";
    this.drawingState.isDragging = false;
    this.drawingState.p1 = null;
    this.drawingState.p2 = null;

    if (this.canvasEl) {
      this.canvasEl.style.pointerEvents = "auto";
      this.canvasEl.style.cursor = "crosshair";
    }
    const btn = this._cardEl?.querySelector(`#btn-draw-roi-${this.streamId}`);
    if (btn) {
      btn.classList.add("ring-2", "ring-amber-400");
    }
    this.renderOverlay();
  }

  cancelDrawing(_keepUnsaved = false) {
    this.drawingState.active = false;
    this.drawingState.mode = null;
    this.drawingState.isDragging = false;
    this.drawingState.p1 = null;
    this.drawingState.p2 = null;

    if (this.canvasEl) {
      this.canvasEl.style.pointerEvents = "none";
      this.canvasEl.style.cursor = "default";
    }
    const btn = this._cardEl?.querySelector(`#btn-draw-roi-${this.streamId}`);
    if (btn) {
      btn.classList.remove("ring-2", "ring-amber-400");
    }
    this.renderOverlay();
  }

  setSaveButtonAlert(isAlert) {
    const btn = this._cardEl?.querySelector(`#btn-save-zone-${this.streamId}`);
    if (!btn) return;
    if (isAlert) {
      btn.classList.add("ring-2", "ring-amber-400", "animate-pulse", "bg-amber-600");
      btn.classList.remove("bg-emerald-600");
      btn.textContent = "保存*";
    } else {
      btn.classList.remove("ring-2", "ring-amber-400", "animate-pulse", "bg-amber-600");
      btn.classList.add("bg-emerald-600");
      btn.textContent = "保存";
    }
  }

  resetZoneToDefault() {
    this.zoneConfig = {
      enabled: true,
      trigger_box: [0.05, 0.05, 0.95, 0.95],
      roi: { type: "rect", coords: [0.05, 0.05, 0.95, 0.95] },
      target_classes: [],
      _hasUnsaved: true,
    };
    this.hasUnsavedChanges = true;
    this.setSaveButtonAlert(true);
    showGlobalToast("已重置", "info");
    this.renderOverlay();
  }

  async saveZoneConfig() {
    const cfg = this.zoneConfig || {
      enabled: true,
      trigger_box: [0.05, 0.05, 0.95, 0.95],
      roi: { type: "rect", coords: [0.05, 0.05, 0.95, 0.95] },
      target_classes: [],
    };
    if (!cfg.trigger_box && cfg.roi && cfg.roi.coords) {
      cfg.trigger_box = cfg.roi.coords;
    }
    delete cfg._hasUnsaved;

    try {
      const res = await fetch(`/api/zone/${this.streamId}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(cfg),
      });

      const data = await res.json().catch(() => null);

      if (res.ok && data && data.success) {
        this.hasUnsavedChanges = false;
        if (this.zoneConfig) this.zoneConfig._hasUnsaved = false;
        if (this._cardEl) this._cardEl.dataset.zoneConfig = JSON.stringify(cfg);
        this.setSaveButtonAlert(false);
        this.renderOverlay();

        const hintMsg = data.gateway_synced === false ? "已保存至本地 (网关未响应)" : "保存成功";
        showGlobalToast(hintMsg, "success");
      } else {
        showGlobalToast("保存失败", "error");
      }
    } catch (err) {
      showGlobalToast("保存失败", "error");
    }
  }
}

export class StreamConfigManager {
  constructor(gridManager) {
    this.gridManager = gridManager;
    this.initElements();
  }

  initElements() {
    this.panelEl = document.getElementById("stream-config-panel");
    this.serverUrlInputEl = document.getElementById("server-base-url");
    this.alertCallbackUrlInputEl = document.getElementById("alert-callback-url");
    this.alertCooldownSecInputEl = document.getElementById("alert-cooldown-sec");
    this.alertTimeoutSecInputEl = document.getElementById("alert-timeout-sec");
    this.rowsContainerEl = document.getElementById("stream-rows-container");
    this.btnAddRowEl = document.getElementById("btn-add-stream-row");
    this.btnSaveEl = document.getElementById("btn-save-streams");
    this.btnSyncGatewayEl = document.getElementById("btn-sync-gateway");
    this.btnGlobalSaveEl = document.getElementById("btn-global-save");
    this.feedbackEl = document.getElementById("stream-config-feedback");

    try {
      localStorage.removeItem("saved_stream_configs");
    } catch (e) {}

    if (!this.rowsContainerEl) return;

    this.bindEvents();
    this.bindExistingRowEvents();
  }

  getServerBaseUrl() {
    let url = this.serverUrlInputEl?.value?.trim() || "";
    if (url && !url.startsWith("http://") && !url.startsWith("https://")) {
      url = "http://" + url;
    }
    return url.replace(/\/+$/, "");
  }

  getAlertCallbackUrl() {
    return this.alertCallbackUrlInputEl?.value?.trim() || "";
  }

  getAlertCooldownSec() {
    const val = parseInt(this.alertCooldownSecInputEl?.value?.trim() || "1", 10);
    return isNaN(val) ? 1 : val;
  }

  getAlertTimeoutSec() {
    const val = parseInt(this.alertTimeoutSecInputEl?.value?.trim() || "3", 10);
    return isNaN(val) ? 3 : val;
  }

  bindEvents() {
    if (this.btnAddRowEl && !this.btnAddRowEl.hasAttribute("phx-click")) {
      this.btnAddRowEl.onclick = () => {
        const count = this.rowsContainerEl ? this.rowsContainerEl.querySelectorAll("tr.stream-row").length : 0;
        const newId = `stream_${count + 1}`;
        this.addStreamRow(newId, "rtsp://192.168.88.20:8554/live");
      };
    }

    if (this.btnGlobalSaveEl && !document.getElementById("config-form")) {
      this.btnGlobalSaveEl.onclick = () => this.saveGlobal();
    }

    if (this.btnSaveEl) {
      this.btnSaveEl.onclick = () => this.saveToLocal();
    }

    if (this.btnSyncGatewayEl) {
      this.btnSyncGatewayEl.onclick = () => this.syncToGateway();
    }
  }

  bindExistingRowEvents() {
    if (!this.rowsContainerEl) return;
    const rows = this.rowsContainerEl.querySelectorAll("tr.stream-row");
    rows.forEach((row) => this.bindRowActions(row));
  }

  bindRowActions(row) {
    const btnRemove = row.querySelector(".btn-remove-row");
    if (btnRemove) {
      btnRemove.onclick = () => {
        row.remove();
        this.reindexRows();
      };
    }
  }

  reindexRows() {
    if (!this.rowsContainerEl) return;
    const rows = this.rowsContainerEl.querySelectorAll("tr.stream-row");
    rows.forEach((row, idx) => {
      const idxCell = row.querySelector(".row-index");
      if (idxCell) idxCell.textContent = idx + 1;
    });
  }

  addStreamRow(streamId = "", rtspUrl = "") {
    if (!this.rowsContainerEl) return;
    const count = this.rowsContainerEl.querySelectorAll("tr.stream-row").length;
    const tr = document.createElement("tr");
    tr.className = "stream-row hover:bg-zinc-50 transition-colors";
    tr.innerHTML = `
      <td class="py-3 px-3 text-center font-mono text-zinc-400 font-semibold row-index">${count + 1}</td>
      <td class="py-3 px-4 w-36">
        <input type="text" class="input-stream-id w-28 sm:w-32 rounded-md border border-zinc-300 px-2.5 py-1.5 font-mono text-xs text-zinc-800 bg-white shadow-inner focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" value="${streamId}" placeholder="stream_1">
      </td>
      <td class="py-3 px-4">
        <input type="text" class="input-stream-url w-full rounded-md border border-zinc-300 px-3 py-1.5 font-mono text-xs text-zinc-800 bg-white shadow-inner focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" value="${rtspUrl}" placeholder="rtsp://192.168.88.20:8554/live">
      </td>
      <td class="py-3 px-4 w-32 text-center">
        <button type="button" class="btn-remove-row inline-flex items-center gap-1 rounded-md bg-red-50 text-red-600 hover:bg-red-100 px-2.5 py-1 font-semibold transition-colors cursor-pointer text-xs">
          删除
        </button>
      </td>
    `;
    this.rowsContainerEl.appendChild(tr);
    this.bindRowActions(tr);
  }

  getStreamsFromDOM() {
    if (!this.rowsContainerEl) return [];
    const rows = this.rowsContainerEl.querySelectorAll("tr.stream-row");
    const list = [];
    rows.forEach((row) => {
      const idInput = row.querySelector(".input-stream-id");
      const urlInput = row.querySelector(".input-stream-url");
      const sId = idInput?.value?.trim() || "";
      const sUrl = urlInput?.value?.trim() || "";
      if (sId && sUrl) {
        list.push({ stream_id: sId, url: sUrl });
      }
    });
    return list;
  }

  showFeedback(msg, type = "info") {
    showGlobalToast(msg, type);
  }

  async saveToLocal() {
    const streams = this.getStreamsFromDOM();
    try {
      const res = await fetch("/api/streams", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ streams }),
      });
      const data = await res.json().catch(() => null);
      if (res.ok && data && data.success) {
        this.showFeedback("已保存到本地配置", "success");
      } else {
        this.showFeedback("保存失败", "error");
      }
    } catch (err) {
      this.showFeedback("保存失败", "error");
    }
  }

  async syncToGateway() {
    const streams = this.getStreamsFromDOM();
    const gatewayUrl = this.getServerBaseUrl();
    if (!gatewayUrl) {
      this.showFeedback("网关地址不能为空", "error");
      return;
    }

    try {
      const res = await fetch("/api/streams/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          gateway_url: gatewayUrl,
          streams,
        }),
      });
      const data = await res.json().catch(() => null);
      if (res.ok && data && data.success) {
        this.showFeedback("已同步至硬件网关", "success");
      } else {
        const errorMsg = data && data.message ? data.message : "网关同步失败";
        this.showFeedback(errorMsg, "error");
      }
    } catch (err) {
      this.showFeedback("网关同步失败", "error");
    }
  }

  async saveGlobal() {
    const streams = this.getStreamsFromDOM();
    const gatewayUrl = this.getServerBaseUrl();
    const alertCallbackUrl = this.getAlertCallbackUrl();
    const alertCooldownSec = this.getAlertCooldownSec();
    const alertTimeoutSec = this.getAlertTimeoutSec();

    if (!gatewayUrl) {
      this.showFeedback("网关地址不能为空", "error");
      return;
    }

    if (this.btnGlobalSaveEl) {
      this.btnGlobalSaveEl.disabled = true;
      this.btnGlobalSaveEl.textContent = "保存中...";
    }

    try {
      const res = await fetch("/api/config/sync-to-hardware", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          gateway_url: gatewayUrl,
          alert_callback_url: alertCallbackUrl,
          alert_cooldown_sec: alertCooldownSec,
          alert_timeout_sec: alertTimeoutSec,
          streams,
        }),
      });
      const data = await res.json().catch(() => null);

      if (res.ok && data && data.success) {
        if (data.hardware_synced) {
          this.showFeedback(data.message || "保存成功，已同步到硬件网关", "success");
        } else {
          this.showFeedback(data.message || "已保存到本地数据库，但硬件网关未同步", "warning");
        }
      } else {
        const errorMsg = data && data.message ? data.message : "保存失败";
        this.showFeedback(errorMsg, "error");
      }
    } catch (err) {
      this.showFeedback("保存失败 (网络异常)", "error");
    } finally {
      if (this.btnGlobalSaveEl) {
        this.btnGlobalSaveEl.disabled = false;
        this.btnGlobalSaveEl.textContent = "保存";
      }
    }
  }
}
