import { drawDetections, renderDetectionList, clientToRelCoords } from "./overlay_renderer";

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

export class Player {
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

    this.zoneConfig = null;
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

    this.rateInterval = null;
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
      if (!this.renderLoopRunning) return;

      try {
        this.renderOverlay();
      } catch (err) {
      } finally {
        if (this.renderLoopRunning) {
          if (this.videoEl && this.videoEl.requestVideoFrameCallback) {
            this.videoEl.requestVideoFrameCallback(renderLoop);
          } else {
            requestAnimationFrame(renderLoop);
          }
        }
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
        this.zoneConfig = msg.zone_config;
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

      if (this.videoEl) {
        this.pc.ontrack = (e) => {
          this.videoEl.srcObject = e.streams[0];
          this.videoEl.play().catch(() => {});
          this.setStatus("已连接", true);
          this.isConnected = true;
          this.startSyncRenderer();
        };
      }

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
    if (this.rateInterval) clearInterval(this.rateInterval);
    this.disconnect();
  }
}

export class StreamCardController {
  constructor(cardEl) {
    if (cardEl._controller) {
      return cardEl._controller;
    }
    cardEl._controller = this;
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

    this.tripCountEl = cardEl.querySelector(`#trip-count-${this.streamId}`);
    this.btnDrawTripwire = cardEl.querySelector(`#btn-draw-tripwire-${this.streamId}`);
    this.btnDrawRoi = cardEl.querySelector(`#btn-draw-roi-${this.streamId}`);
    this.btnResetZone = cardEl.querySelector(`#btn-reset-zone-${this.streamId}`);
    this.btnSaveZone = cardEl.querySelector(`#btn-save-zone-${this.streamId}`);

    const resolvedUrl = this.getResolvedUrl();

    this.player = new Player({
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
    this.bindCalibrationEvents();
    this.fetchZoneConfig().finally(() => {
      this.player.renderOverlay();
    });

    if (window.ResizeObserver && this.videoWrapEl) {
      const ro = new ResizeObserver(() => {
        if (!this.player.renderLoopRunning) {
          this.player.renderOverlay();
        }
      });
      ro.observe(this.videoWrapEl);
    }
  }

  getResolvedUrl() {
    const baseUrl = this.getApiBaseUrl();
    const inputVal = this.urlInputEl?.value?.trim();
    if (!inputVal) {
      return this.customUrl || (baseUrl ? `${baseUrl}/${this.streamId}` : "");
    }
    if (inputVal.startsWith("http://") || inputVal.startsWith("https://")) {
      return inputVal;
    }
    return baseUrl ? `${baseUrl}/${inputVal}` : inputVal;
  }

  getApiBaseUrl() {
    try {
      const grid = document.getElementById("stream-cards-grid");
      if (grid && grid.getAttribute("data-gateway-url")) {
        let v = grid.getAttribute("data-gateway-url").trim();
        if (v && !v.startsWith("http://") && !v.startsWith("https://")) v = "http://" + v;
        return v.replace(/\/+$/, "");
      }
      const serverBaseInput = document.getElementById("server-base-url");
      if (serverBaseInput && serverBaseInput.value.trim()) {
        let v = serverBaseInput.value.trim();
        if (v && !v.startsWith("http://") && !v.startsWith("https://")) v = "http://" + v;
        return v.replace(/\/+$/, "");
      }
      const urlStr = this.urlInputEl?.value?.trim() || this.customUrl || "";
      if (urlStr) {
        const parsed = new URL(urlStr.startsWith("http") ? urlStr : `http://${urlStr}`);
        return parsed.origin;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  async fetchZoneConfig() {
    if (this.cardEl && this.cardEl.dataset.zoneConfig) {
      try {
        const localCfg = JSON.parse(this.cardEl.dataset.zoneConfig);
        if (localCfg) {
          this.player.zoneConfig = localCfg;
          this.player.renderOverlay();
        }
      } catch (e) {}
    }

    try {
      const res = await fetch(`/api/zone/${this.streamId}`);
      if (res.ok) {
        const data = await res.json();
        if (data.config) {
          this.player.zoneConfig = data.config;
          this.player.renderOverlay();
        }
      }
    } catch (e) {}
  }

  bindEvents() {
    if (this.connectBtnEl) {
      this.connectBtnEl.onclick = () => {
        this.player.url = this.getResolvedUrl();
        this.player.toggleConnect();
      };
    }
    if (this.fsBtnEl && this.videoWrapEl) {
      this.fsBtnEl.onclick = () => {
        if (this.videoWrapEl.requestFullscreen) this.videoWrapEl.requestFullscreen();
      };
    }
  }

  bindCalibrationEvents() {
    if (this.btnDrawTripwire) {
      this.btnDrawTripwire.onclick = () => {
        if (this.player.drawingState.active) {
          this.cancelDrawing();
        } else {
          this.startDrawing("tripwire");
        }
      };
    }
    if (this.btnDrawRoi) {
      this.btnDrawRoi.onclick = () => {
        if (this.player.drawingState.active) {
          this.cancelDrawing();
        } else {
          this.startDrawing("roi");
        }
      };
    }
    if (this.btnResetZone) {
      this.btnResetZone.onclick = () => this.resetZoneToDefault();
    }
    if (this.btnSaveZone) {
      this.btnSaveZone.onclick = () => this.saveZoneConfig();
    }

    if (this.canvasEl) {
      const onGlobalMouseMove = (e) => {
        if (!this.player.drawingState.active || !this.player.drawingState.isDragging) return;
        e.preventDefault();
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.player.drawingState.p2 = pt;
        this.player.renderOverlay();
      };

      const onGlobalMouseUp = (e) => {
        if (!this.player.drawingState.active || !this.player.drawingState.isDragging) return;
        this.player.drawingState.isDragging = false;
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.player.drawingState.p2 = pt;

        const p1 = this.player.drawingState.p1;
        const p2 = this.player.drawingState.p2;

        if (p1 && p2) {
          const dx = Math.abs(p2[0] - p1[0]);
          const dy = Math.abs(p2[1] - p1[1]);

          if (dx >= 0.02 && dy >= 0.02) {
            const x1 = Math.min(p1[0], p2[0]);
            const y1 = Math.min(p1[1], p2[1]);
            const x2 = Math.max(p1[0], p2[0]);
            const y2 = Math.max(p1[1], p2[1]);
            const boxRect = [x1, y1, x2, y2];

            if (!this.player.zoneConfig) {
              this.player.zoneConfig = {
                enabled: true,
                target_classes: [],
              };
            }

            this.player.zoneConfig.trigger_box = boxRect;
            this.player.zoneConfig.roi = {
              type: "rect",
              coords: boxRect,
            };
            this.player.zoneConfig._hasUnsaved = true;
            this.player.hasUnsavedChanges = true;

            this.setSaveButtonAlert(true);
          }
        }

        this.cancelDrawing(true);
        this.player.renderOverlay();
      };

      this.canvasEl.onmousedown = (e) => {
        if (!this.player.drawingState.active) return;
        e.preventDefault();
        const pt = clientToRelCoords(this.videoEl, this.canvasEl, e.clientX, e.clientY);
        this.player.drawingState.p1 = pt;
        this.player.drawingState.p2 = pt;
        this.player.drawingState.isDragging = true;
        this.player.renderOverlay();
      };

      window.addEventListener("mousemove", onGlobalMouseMove);
      window.addEventListener("mouseup", onGlobalMouseUp);

      window.addEventListener("keydown", (e) => {
        if (e.key === "Escape" && this.player.drawingState.active) {
          this.cancelDrawing();
        }
      });
    }
  }

  startDrawing(mode) {
    this.player.drawingState.active = true;
    this.player.drawingState.mode = mode || "trigger_box";
    this.player.drawingState.isDragging = false;
    this.player.drawingState.p1 = null;
    this.player.drawingState.p2 = null;

    if (this.canvasEl) {
      this.canvasEl.style.pointerEvents = "auto";
      this.canvasEl.style.cursor = "crosshair";
    }
    if (this.btnDrawRoi) {
      this.btnDrawRoi.classList.add("ring-2", "ring-amber-400");
    }
    this.player.renderOverlay();
  }

  cancelDrawing(_keepUnsaved = false) {
    this.player.drawingState.active = false;
    this.player.drawingState.mode = null;
    this.player.drawingState.isDragging = false;
    this.player.drawingState.p1 = null;
    this.player.drawingState.p2 = null;
    if (this.canvasEl) {
      this.canvasEl.style.pointerEvents = "none";
      this.canvasEl.style.cursor = "default";
    }
    if (this.btnDrawRoi) {
      this.btnDrawRoi.classList.remove("ring-2", "ring-amber-400");
    }
    this.player.renderOverlay();
  }

  showHint(msg, type = "info") {
    showGlobalToast(msg, type);
  }

  setSaveButtonAlert(isAlert) {
    if (!this.btnSaveZone) return;
    if (isAlert) {
      this.btnSaveZone.classList.add("ring-2", "ring-amber-400", "animate-pulse", "bg-amber-600");
      this.btnSaveZone.classList.remove("bg-emerald-600");
      this.btnSaveZone.textContent = "保存*";
    } else {
      this.btnSaveZone.classList.remove("ring-2", "ring-amber-400", "animate-pulse", "bg-amber-600");
      this.btnSaveZone.classList.add("bg-emerald-600");
      this.btnSaveZone.textContent = "保存";
    }
  }

  resetZoneToDefault() {
    this.player.zoneConfig = {
      enabled: true,
      trigger_box: [0.05, 0.05, 0.95, 0.95],
      roi: { type: "rect", coords: [0.05, 0.05, 0.95, 0.95] },
      target_classes: [],
      _hasUnsaved: true,
    };
    this.player.hasUnsavedChanges = true;
    this.setSaveButtonAlert(true);
    this.showHint("已重置", "info");
    this.player.renderOverlay();
  }

  async saveZoneConfig() {
    const cfg = this.player.zoneConfig || {
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
        this.player.hasUnsavedChanges = false;
        if (this.player.zoneConfig) this.player.zoneConfig._hasUnsaved = false;
        if (this.cardEl) this.cardEl.dataset.zoneConfig = JSON.stringify(cfg);
        this.setSaveButtonAlert(false);
        this.player.renderOverlay();
        const hintMsg = data.gateway_synced === false ? "已保存至本地 (网关未响应)" : "保存成功";
        this.showHint(hintMsg, "success");
      } else {
        this.showHint("保存失败", "error");
      }
    } catch (err) {
      this.showHint("保存失败", "error");
    }
  }

  connect() {
    this.player.url = this.getResolvedUrl();
    return this.player.connect();
  }

  disconnect() {
    return this.player.disconnect();
  }

  destroy() {
    this.player.destroy();
    if (this.cardEl) {
      delete this.cardEl._controller;
      if (this.cardEl.parentNode) {
        this.cardEl.parentNode.removeChild(this.cardEl);
      }
    }
  }
}

export class StreamGridManager {
  constructor() {
    this.gridContainer = document.getElementById("stream-cards-grid");
    this.templateEl = document.getElementById("stream-card-template");
    this.controllers = new Map();
    this.counter = 0;

    try {
      localStorage.removeItem("saved_stream_configs");
    } catch (e) {}

    if (!this.gridContainer) return;
    this.initCards();
    this.bindGlobalButtons();
  }

  getBaseUrl() {
    if (this.gridContainer && this.gridContainer.getAttribute("data-gateway-url")) {
      let v = this.gridContainer.getAttribute("data-gateway-url").trim();
      if (!v.startsWith("http://") && !v.startsWith("https://")) v = "http://" + v;
      return v.replace(/\/+$/, "");
    }
    const serverBaseInput = document.getElementById("server-base-url");
    let baseUrl = serverBaseInput?.value?.trim() || "http://192.168.88.100:8181";
    if (!baseUrl.startsWith("http://") && !baseUrl.startsWith("https://")) baseUrl = "http://" + baseUrl;
    return baseUrl.replace(/\/+$/, "");
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
    if (this.btnAddRowEl) {
      this.btnAddRowEl.onclick = () => {
        const count = this.rowsContainerEl ? this.rowsContainerEl.querySelectorAll("tr.stream-row").length : 0;
        const newId = `stream_${count + 1}`;
        this.addStreamRow(newId, "rtsp://192.168.88.20:8554/live");
      };
    }

    if (this.btnGlobalSaveEl) {
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
    rows.forEach((tr) => {
      const removeBtn = tr.querySelector(".btn-remove-row");
      if (removeBtn) {
        removeBtn.onclick = () => {
          tr.remove();
          this.updateRowIndices();
        };
      }
    });
  }

  showFeedback(msg, type = "success") {
    if (!this.feedbackEl) return;
    const baseClasses =
      "fixed top-6 left-1/2 -translate-x-1/2 z-50 px-5 py-2.5 rounded-xl shadow-lg border text-xs font-semibold tracking-wide transition-all pointer-events-none ";
    const styleClasses =
      type === "success"
        ? "bg-white text-emerald-700 border-emerald-200 shadow-emerald-500/10"
        : type === "warning"
        ? "bg-white text-amber-700 border-amber-200 shadow-amber-500/10"
        : type === "error"
        ? "bg-white text-red-700 border-red-200 shadow-red-500/10"
        : "bg-white text-blue-700 border-blue-200 shadow-blue-500/10";

    this.feedbackEl.className = baseClasses + styleClasses;
    this.feedbackEl.textContent = msg;
    this.feedbackEl.classList.remove("hidden");

    if (this._feedbackTimer) clearTimeout(this._feedbackTimer);
    this._feedbackTimer = setTimeout(() => {
      if (this.feedbackEl) {
        this.feedbackEl.classList.add("hidden");
      }
    }, 3000);
  }

  addStreamRow(id = "", url = "") {
    if (!this.rowsContainerEl) return;
    const count = this.rowsContainerEl.querySelectorAll("tr.stream-row").length + 1;
    const tr = document.createElement("tr");
    tr.className = "stream-row hover:bg-zinc-50 transition-colors";
    tr.innerHTML = `
      <td class="py-3 px-3 text-center font-mono text-zinc-400 font-semibold row-index">${count}</td>
      <td class="py-3 px-4 w-36">
        <input
          type="text"
          class="input-stream-id w-28 sm:w-32 rounded-md border border-zinc-300 px-2.5 py-1.5 font-mono text-xs text-zinc-800 bg-white shadow-inner focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
          value="${id}"
        />
      </td>
      <td class="py-3 px-4">
        <input
          type="text"
          class="input-stream-url w-full rounded-md border border-zinc-300 px-3 py-1.5 font-mono text-xs text-zinc-800 bg-white shadow-inner focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
          value="${url}"
        />
      </td>
      <td class="py-3 px-4 text-center">
        <button
          type="button"
          class="btn-remove-row rounded border border-red-200 bg-red-50 text-red-600 hover:bg-red-100 hover:border-red-300 px-2.5 py-1 text-xs font-semibold cursor-pointer transition-colors shadow-2xs flex items-center justify-center gap-1 mx-auto"
          title="删除此路直播流通道"
        >
          删除
        </button>
      </td>
    `;

    const removeBtn = tr.querySelector(".btn-remove-row");
    if (removeBtn) {
      removeBtn.onclick = () => {
        tr.remove();
        this.updateRowIndices();
      };
    }

    this.rowsContainerEl.appendChild(tr);
  }

  updateRowIndices() {
    if (!this.rowsContainerEl) return;
    const rows = this.rowsContainerEl.querySelectorAll("tr.stream-row");
    rows.forEach((row, i) => {
      const idxEl = row.querySelector(".row-index");
      if (idxEl) idxEl.textContent = i + 1;
    });
  }

  renderStreamRows(streams) {
    if (!this.rowsContainerEl) return;
    this.rowsContainerEl.innerHTML = "";
    for (const s of streams) {
      this.addStreamRow(s.id || s.stream_id, s.url || s.rtsp_url);
    }
  }

  getStreamsFromUI() {
    if (!this.rowsContainerEl) return [];
    const rows = this.rowsContainerEl.querySelectorAll("tr.stream-row");
    const list = [];
    rows.forEach((row) => {
      const idInput = row.querySelector(".input-stream-id");
      const urlInput = row.querySelector(".input-stream-url");
      const id = idInput?.value?.trim() || "";
      const url = urlInput?.value?.trim() || "";
      if (id || url) {
        list.push({ id, url });
      }
    });
    return list;
  }

  validateStreams(streams) {
    if (streams.length === 0) {
      this.showFeedback("请至少保留一路流", "error");
      return false;
    }

    const seenIds = new Set();
    for (let i = 0; i < streams.length; i++) {
      const { id, url } = streams[i];
      if (!id) {
        this.showFeedback("流标识不能为空", "error");
        return false;
      }
      if (!/^[a-zA-Z0-9_\-]+$/.test(id)) {
        this.showFeedback("流标识格式不合法", "error");
        return false;
      }
      if (seenIds.has(id)) {
        this.showFeedback("流标识重复", "error");
        return false;
      }
      seenIds.add(id);

      if (!url) {
        this.showFeedback("rtsp 流地址不能为空", "error");
        return false;
      }
    }
    return true;
  }

  async saveToLocal() {
    const streams = this.getStreamsFromUI();
    if (!this.validateStreams(streams)) return;

    const gatewayUrl = this.getServerBaseUrl();
    const alertCallbackUrl = this.getAlertCallbackUrl();
    const alertCooldownSec = this.getAlertCooldownSec();
    const alertTimeoutSec = this.getAlertTimeoutSec();
    if (this.btnSaveEl) {
      this.btnSaveEl.disabled = true;
      this.btnSaveEl.textContent = "保存中...";
    }

    try {
      const res = await fetch("/api/config/save-local", {
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
      const data = await res.json();
      if (res.ok && data.success) {
        this.showFeedback("保存成功", "success");
      } else {
        this.showFeedback("保存失败", "error");
      }
    } catch (err) {
      this.showFeedback("保存失败", "error");
    } finally {
      if (this.btnSaveEl) {
        this.btnSaveEl.disabled = false;
        this.btnSaveEl.textContent = "保存";
      }
    }
  }

  async syncToGateway() {
    const streams = this.getStreamsFromUI();
    if (!this.validateStreams(streams)) return;

    const gatewayUrl = this.getServerBaseUrl();
    const alertCallbackUrl = this.getAlertCallbackUrl();
    const alertCooldownSec = this.getAlertCooldownSec();
    const alertTimeoutSec = this.getAlertTimeoutSec();
    if (this.btnSyncGatewayEl) {
      this.btnSyncGatewayEl.disabled = true;
      this.btnSyncGatewayEl.textContent = "同步中...";
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
        this.showFeedback("同步成功", "success");
      } else {
        const errorMsg = (data && data.message) ? data.message : "同步失败";
        this.showFeedback(errorMsg, "error");
      }
    } catch (err) {
      this.showFeedback("同步失败 (网络异常)", "error");
    } finally {
      if (this.btnSyncGatewayEl) {
        this.btnSyncGatewayEl.disabled = false;
        this.btnSyncGatewayEl.textContent = "配置同步到网关";
      }
    }
  }

  async saveGlobal() {
    const streams = this.getStreamsFromUI();
    if (!this.validateStreams(streams)) return;

    const gatewayUrl = this.getServerBaseUrl();
    const alertCallbackUrl = this.getAlertCallbackUrl();
    const alertCooldownSec = this.getAlertCooldownSec();
    const alertTimeoutSec = this.getAlertTimeoutSec();

    if (this.btnGlobalSaveEl) {
      this.btnGlobalSaveEl.disabled = true;
      this.btnGlobalSaveEl.innerHTML = `
        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        保存中...
      `;
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

export function initPlayerUI() {
  if (!window._gridManager && document.getElementById("stream-cards-grid")) {
    window._gridManager = new StreamGridManager();
  } else if (window._gridManager) {
    window._gridManager.gridContainer = document.getElementById("stream-cards-grid");
    window._gridManager.initCards();
    window._gridManager.bindGlobalButtons();
  }

  if (!window._configManager && document.getElementById("stream-rows-container")) {
    window._configManager = new StreamConfigManager(window._gridManager);
  } else if (window._configManager) {
    window._configManager.initElements();
  }

  return { gridManager: window._gridManager, configManager: window._configManager };
}

export const initWebRtcUI = initPlayerUI;
