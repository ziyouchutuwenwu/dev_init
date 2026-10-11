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

export function getColorForClass(clsId, label) {
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

export function getVideoRenderBox(video, canvas) {
  const displayW =
    (canvas && canvas.clientWidth > 0 ? canvas.clientWidth : 0) ||
    (video && video.clientWidth > 0 ? video.clientWidth : 0) ||
    (canvas && canvas.getBoundingClientRect ? canvas.getBoundingClientRect().width : 0) ||
    (video && video.getBoundingClientRect ? video.getBoundingClientRect().width : 0) ||
    640;

  const displayH =
    (canvas && canvas.clientHeight > 0 ? canvas.clientHeight : 0) ||
    (video && video.clientHeight > 0 ? video.clientHeight : 0) ||
    (canvas && canvas.getBoundingClientRect ? canvas.getBoundingClientRect().height : 0) ||
    (video && video.getBoundingClientRect ? video.getBoundingClientRect().height : 0) ||
    360;

  if (!video || !video.videoWidth || !video.videoHeight || video.videoWidth <= 0 || video.videoHeight <= 0) {
    return { renderW: displayW, renderH: displayH, offsetX: 0, offsetY: 0, displayW, displayH };
  }

  const intrinsicW = video.videoWidth;
  const intrinsicH = video.videoHeight;

  if (intrinsicW <= 0 || intrinsicH <= 0 || displayW <= 0 || displayH <= 0) {
    return { renderW: displayW, renderH: displayH, offsetX: 0, offsetY: 0, displayW, displayH };
  }

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

  return { renderW, renderH, offsetX, offsetY, displayW, displayH };
}

export function clientToRelCoords(video, canvas, clientX, clientY) {
  if (clientY === undefined) {
    clientY = clientX;
    clientX = canvas;
    canvas = (video && video.tagName === "CANVAS") ? video : null;
  }
  const refEl = canvas || video;
  if (!refEl) return [0, 0];

  const rect = refEl.getBoundingClientRect();
  const box = getVideoRenderBox(video, canvas);

  const canvasX = clientX - rect.left;
  const canvasY = clientY - rect.top;

  const renderW = box.renderW > 0 ? box.renderW : (rect.width > 0 ? rect.width : 640);
  const renderH = box.renderH > 0 ? box.renderH : (rect.height > 0 ? rect.height : 360);

  const rx = Math.max(0, Math.min(1, (canvasX - box.offsetX) / renderW));
  const ry = Math.max(0, Math.min(1, (canvasY - box.offsetY) / renderH));
  return [rx, ry];
}

export function drawDetections(canvas, video, detections, frameW, frameH, zoneConfig = null, drawingState = null) {
  if (!canvas) return;
  const ctx = canvas.getContext("2d");

  const box = getVideoRenderBox(video, canvas);
  const { renderW, renderH, offsetX, offsetY, displayW, displayH } = box;

  if (canvas.width !== displayW || canvas.height !== displayH) {
    canvas.width = displayW;
    canvas.height = displayH;
  }
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const isDraggingNow = Boolean(
    drawingState &&
    drawingState.active &&
    drawingState.isDragging &&
    drawingState.p1 &&
    drawingState.p2
  );

  let triggerBox = null;
  if (isDraggingNow) {
    const p1 = drawingState.p1;
    const p2 = drawingState.p2;
    triggerBox = [
      Math.min(p1[0], p2[0]),
      Math.min(p1[1], p2[1]),
      Math.max(p1[0], p2[0]),
      Math.max(p1[1], p2[1]),
    ];
  } else if (zoneConfig) {
    triggerBox = zoneConfig.trigger_box || null;
    if (!triggerBox && zoneConfig.roi) {
      if (zoneConfig.roi.type === "rect" && Array.isArray(zoneConfig.roi.coords)) {
        triggerBox = zoneConfig.roi.coords;
      } else if (Array.isArray(zoneConfig.roi)) {
        triggerBox = zoneConfig.roi;
      }
    }
  }

  if (triggerBox && triggerBox.length >= 4 && (zoneConfig?.enabled !== false || isDraggingNow)) {
    ctx.save();
    const rx = offsetX + Math.min(triggerBox[0], triggerBox[2]) * renderW;
    const ry = offsetY + Math.min(triggerBox[1], triggerBox[3]) * renderH;
    const rw = Math.abs(triggerBox[2] - triggerBox[0]) * renderW;
    const rh = Math.abs(triggerBox[3] - triggerBox[1]) * renderH;

    const isUnsaved = Boolean(drawingState?.hasUnsavedChanges || zoneConfig?._hasUnsaved);

    if (isDraggingNow) {
      ctx.fillStyle = "rgba(245, 158, 11, 0.18)";
      ctx.fillRect(rx, ry, rw, rh);

      ctx.strokeStyle = "#f59e0b";
      ctx.lineWidth = 2.5;
      ctx.setLineDash([6, 3]);
      ctx.strokeRect(rx, ry, rw, rh);

      ctx.setLineDash([]);
      ctx.strokeStyle = "#fbbf24";
      ctx.lineWidth = 4.0;
      const cLen = Math.min(20, rw / 3, rh / 3);

      ctx.beginPath();
      ctx.moveTo(rx, ry + cLen); ctx.lineTo(rx, ry); ctx.lineTo(rx + cLen, ry);
      ctx.moveTo(rx + rw - cLen, ry); ctx.lineTo(rx + rw, ry); ctx.lineTo(rx + rw, ry + cLen);
      ctx.moveTo(rx, ry + rh - cLen); ctx.lineTo(rx, ry + rh); ctx.lineTo(rx + cLen, ry + rh);
      ctx.moveTo(rx + rw - cLen, ry + rh); ctx.lineTo(rx + rw, ry + rh); ctx.lineTo(rx + rw, ry + rh - cLen);
      ctx.stroke();

      const labelText = `触发区域 (标定中: ${Math.round(rw)}×${Math.round(rh)})`;
      ctx.font = "bold 11px sans-serif";
      const txtWidth = ctx.measureText(labelText).width + 16;
      ctx.fillStyle = "rgba(217, 119, 6, 0.95)";
      ctx.fillRect(rx, ry, txtWidth, 22);
      ctx.fillStyle = "#ffffff";
      ctx.fillText(labelText, rx + 8, ry + 15);
    } else {
      ctx.fillStyle = isUnsaved ? "rgba(245, 158, 11, 0.12)" : "rgba(245, 158, 11, 0.05)";
      ctx.fillRect(rx, ry, rw, rh);

      ctx.strokeStyle = isUnsaved ? "rgba(234, 88, 12, 0.95)" : "rgba(245, 158, 11, 0.85)";
      ctx.lineWidth = 2.0;
      ctx.setLineDash([8, 4]);
      ctx.strokeRect(rx, ry, rw, rh);

      ctx.setLineDash([]);
      ctx.strokeStyle = isUnsaved ? "#ea580c" : "#f59e0b";
      ctx.lineWidth = 3.5;
      const cLen = Math.min(18, rw / 4, rh / 4);

      ctx.beginPath();
      ctx.moveTo(rx, ry + cLen); ctx.lineTo(rx, ry); ctx.lineTo(rx + cLen, ry);
      ctx.moveTo(rx + rw - cLen, ry); ctx.lineTo(rx + rw, ry); ctx.lineTo(rx + rw, ry + cLen);
      ctx.moveTo(rx, ry + rh - cLen); ctx.lineTo(rx, ry + rh); ctx.lineTo(rx + cLen, ry + rh);
      ctx.moveTo(rx + rw - cLen, ry + rh); ctx.lineTo(rx + rw, ry + rh); ctx.lineTo(rx + rw, ry + rh - cLen);
      ctx.stroke();

      const labelText = isUnsaved
        ? "触发区域 (待保存)"
        : "触发区域";
      ctx.font = "bold 11px sans-serif";
      const txtWidth = ctx.measureText(labelText).width + 16;
      ctx.fillStyle = isUnsaved ? "rgba(234, 88, 12, 0.95)" : "rgba(245, 158, 11, 0.95)";
      ctx.fillRect(rx, ry, txtWidth, 20);
      ctx.fillStyle = "#ffffff";
      ctx.fillText(labelText, rx + 8, ry + 14);
    }
    ctx.restore();
  }

  if (!isDraggingNow && !triggerBox && zoneConfig && zoneConfig.enabled && zoneConfig.tripwire && zoneConfig.tripwire.line) {
    ctx.save();
    const l = zoneConfig.tripwire.line;
    if (Array.isArray(l) && l.length >= 2) {
      const p1x = offsetX + l[0][0] * renderW;
      const p1y = offsetY + l[0][1] * renderH;
      const p2x = offsetX + l[1][0] * renderW;
      const p2y = offsetY + l[1][1] * renderH;

      ctx.strokeStyle = "rgba(245, 158, 11, 0.35)";
      ctx.lineWidth = 6;
      ctx.beginPath();
      ctx.moveTo(p1x, p1y);
      ctx.lineTo(p2x, p2y);
      ctx.stroke();

      ctx.strokeStyle = "#f59e0b";
      ctx.lineWidth = 2.5;
      ctx.setLineDash([8, 4]);
      ctx.beginPath();
      ctx.moveTo(p1x, p1y);
      ctx.lineTo(p2x, p2y);
      ctx.stroke();

      ctx.setLineDash([]);
      ctx.fillStyle = "#f59e0b";
      ctx.beginPath();
      ctx.arc(p1x, p1y, 4, 0, Math.PI * 2);
      ctx.arc(p2x, p2y, 4, 0, Math.PI * 2);
      ctx.fill();

      const midX = (p1x + p2x) / 2;
      const midY = (p1y + p2y) / 2;
      ctx.fillStyle = "rgba(245, 158, 11, 0.95)";
      ctx.fillRect(midX - 55, midY - 11, 110, 18);
      ctx.fillStyle = "#ffffff";
      ctx.font = "bold 11px sans-serif";
      ctx.fillText("📏 虚拟触发带 (+1)", midX - 50, midY + 2);
    }
    ctx.restore();
  }

  if (drawingState && drawingState.active && drawingState.p1 && drawingState.p2 && drawingState.mode === "tripwire") {
    ctx.save();
    const p1x = offsetX + drawingState.p1[0] * renderW;
    const p1y = offsetY + drawingState.p1[1] * renderH;
    const p2x = offsetX + drawingState.p2[0] * renderW;
    const p2y = offsetY + drawingState.p2[1] * renderH;

    ctx.strokeStyle = "#ef4444";
    ctx.lineWidth = 3;
    ctx.setLineDash([6, 4]);
    ctx.beginPath();
    ctx.moveTo(p1x, p1y);
    ctx.lineTo(p2x, p2y);
    ctx.stroke();

    ctx.fillStyle = "#ef4444";
    ctx.beginPath();
    ctx.arc(p1x, p1y, 5, 0, Math.PI * 2);
    ctx.arc(p2x, p2y, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  if (drawingState && drawingState.active && !isDraggingNow) {
    ctx.save();
    const promptText = "请在画面中按住鼠标左键并拖拽，以设定触发区域 (ESC取消)";
    ctx.font = "bold 12px sans-serif";
    const pWidth = ctx.measureText(promptText).width + 24;
    const px = Math.max(10, (displayW - pWidth) / 2);
    const py = 12;

    ctx.fillStyle = "rgba(15, 23, 42, 0.88)";
    ctx.strokeStyle = "#f59e0b";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    if (ctx.roundRect) {
      ctx.roundRect(px, py, pWidth, 26, 6);
    } else {
      ctx.rect(px, py, pWidth, 26);
    }
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#fbbf24";
    ctx.fillText(promptText, px + 12, py + 17);
    ctx.restore();
  }

  if (!detections || detections.length === 0) return;

  const intrinsicW = (video && video.videoWidth) || frameW || 1920;
  const intrinsicH = (video && video.videoHeight) || frameH || 1080;

  ctx.lineWidth = 2.5;
  ctx.font = "bold 12px sans-serif";

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
    const trackPrefix = d.track_id !== undefined ? `ID:#${d.track_id} ` : "";
    const labelText = trackPrefix + (d.label || ("class_" + d.class_id)) + (confStr ? " " + confStr : "");
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
  if (!detections || !detections.length) {
    if (listEl.dataset.emptyState === "true") return;
    listEl.dataset.emptyState = "true";
    listEl.innerHTML = '<li class="text-zinc-400">暂无目标</li>';
    return;
  }

  if (listEl.dataset.emptyState === "true") {
    listEl.innerHTML = "";
    listEl.dataset.emptyState = "false";
  }

  const existingItems = listEl.children;
  const targetCount = detections.length;

  while (existingItems.length > targetCount) {
    listEl.removeChild(listEl.lastElementChild);
  }

  for (let i = 0; i < targetCount; i++) {
    const d = detections[i];
    let li, dot, text, right;

    if (i < existingItems.length) {
      li = existingItems[i];
      const left = li.firstElementChild;
      dot = left ? left.firstElementChild : null;
      text = left ? left.lastElementChild : null;
      right = li.lastElementChild;
    } else {
      li = document.createElement("li");
      li.className =
        "flex items-center justify-between rounded border border-zinc-100 bg-zinc-50 px-2.5 py-1.5 text-xs";
      const left = document.createElement("span");
      left.className = "font-medium text-zinc-800 flex items-center gap-1.5";

      dot = document.createElement("span");
      dot.className = "w-2.5 h-2.5 rounded-full inline-block";
      left.appendChild(dot);

      text = document.createElement("span");
      left.appendChild(text);

      right = document.createElement("span");
      right.className = "font-mono text-zinc-500 text-xs";
      li.append(left, right);
      listEl.appendChild(li);
    }

    if (dot) {
      const color = getColorForClass(d.class_id, d.label);
      if (dot.style.backgroundColor !== color) {
        dot.style.backgroundColor = color;
      }
    }

    if (text) {
      const trackStr = d.track_id !== undefined ? `[#${d.track_id}] ` : "";
      const labelVal = trackStr + (d.label || ("class_" + d.class_id));
      if (text.textContent !== labelVal) {
        text.textContent = labelVal;
      }
    }

    if (right) {
      const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
      let coordStr = "";
      if (d.rel_box && Array.isArray(d.rel_box)) {
        coordStr = "[" + d.rel_box.map((v) => (v * 100).toFixed(0) + "%").join(",") + "]";
      }
      const rightVal = confStr + (coordStr ? " " + coordStr : "");
      if (right.textContent !== rightVal) {
        right.textContent = rightVal;
      }
    }
  }
}
