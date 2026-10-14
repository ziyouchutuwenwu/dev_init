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

function isPointInPolygon(x, y, vs) {
  if (!vs || vs.length < 3) return false;
  let inside = false;
  for (let i = 0, j = vs.length - 1; i < vs.length; j = i++) {
    const xi = vs[i][0], yi = vs[i][1];
    const xj = vs[j][0], yj = vs[j][1];
    const intersect = ((yi > y) !== (yj > y)) && (x < ((xj - xi) * (y - yi)) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

function normalizeZoneConfig(cfg) {
  if (!cfg) return null;
  if (typeof cfg === "object") return cfg;
  if (typeof cfg === "string") {
    try {
      return JSON.parse(cfg);
    } catch (e) {
      return null;
    }
  }
  return null;
}

export function isDetectionInZone(d, zoneConfig = null, overrideBox = null, rx1 = null, ry1 = null, rx2 = null, ry2 = null) {
  if (!d) return false;

  const cfg = normalizeZoneConfig(zoneConfig);
  if (cfg && cfg.enabled === false) {
    return false;
  }

  let zBox = overrideBox;
  if (!zBox && cfg) {
    zBox = cfg.trigger_box || null;
    if (!zBox && cfg.roi) {
      if (cfg.roi.type === "rect" && Array.isArray(cfg.roi.coords)) {
        zBox = cfg.roi.coords;
      } else if (Array.isArray(cfg.roi) && cfg.roi.length >= 4) {
        zBox = cfg.roi;
      }
    }
  }

  if (zBox && Array.isArray(zBox) && zBox.length >= 4) {
    const minX = Math.min(zBox[0], zBox[2]);
    const maxX = Math.max(zBox[0], zBox[2]);
    const minY = Math.min(zBox[1], zBox[3]);
    const maxY = Math.max(zBox[1], zBox[3]);

    let cx = null, cy = null;
    let x1 = rx1, y1 = ry1, x2 = rx2, y2 = ry2;
    if (x1 === null || y1 === null || x2 === null || y2 === null) {
      if (d.rel_box && Array.isArray(d.rel_box) && d.rel_box.length >= 4) {
        [x1, y1, x2, y2] = d.rel_box;
      } else if (d.box && Array.isArray(d.box) && d.box.length >= 4) {
        [x1, y1, x2, y2] = d.box;
      }
    }

    if (x1 !== null && y1 !== null && x2 !== null && y2 !== null) {
      cx = (x1 + x2) / 2;
      cy = (y1 + y2) / 2;
    } else if (d.center && Array.isArray(d.center) && d.center.length >= 2) {
      cx = d.center[0];
      cy = d.center[1];
    }

    if (cx !== null && cy !== null) {
      return cx >= minX && cx <= maxX && cy >= minY && cy <= maxY;
    }

    return false;
  }

  if (cfg?.roi?.type === "polygon" && Array.isArray(cfg.roi.coords)) {
    const pts = cfg.roi.coords;
    let cx = null, cy = null;
    if (d.center && Array.isArray(d.center) && d.center.length >= 2) {
      cx = d.center[0];
      cy = d.center[1];
    } else if (d.rel_box && Array.isArray(d.rel_box) && d.rel_box.length >= 4) {
      cx = (d.rel_box[0] + d.rel_box[2]) / 2;
      cy = (d.rel_box[1] + d.rel_box[3]) / 2;
    }
    if (cx !== null && cy !== null) {
      return isPointInPolygon(cx, cy, pts);
    }
    return false;
  }

  // 若没有配置标定区域或标定区域未就绪，仅按触发状态判定（不在标定区内的一律不画框）
  if (d.triggered !== undefined || d.crossed !== undefined) {
    return Boolean(d.triggered || d.crossed);
  }

  return false;
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

  const parsedZone = normalizeZoneConfig(zoneConfig);

  const isDraggingNow = Boolean(
    drawingState &&
    drawingState.active &&
    drawingState.isDragging &&
    drawingState.p1 &&
    drawingState.p2
  );

  let origBox = null;
  if (parsedZone) {
    origBox = parsedZone.trigger_box || null;
    if (!origBox && parsedZone.roi) {
      if (parsedZone.roi.type === "rect" && Array.isArray(parsedZone.roi.coords)) {
        origBox = parsedZone.roi.coords;
      } else if (Array.isArray(parsedZone.roi)) {
        origBox = parsedZone.roi;
      }
    }
  }

  const isDrawingActive = Boolean(drawingState && drawingState.active);

  // 1. 若处于标定模式（无论是刚点击“重新标定”还是正在拖拽），原区域边框都立即显示为高辨识度的天蓝色虚线参考框
  if (isDrawingActive && origBox && origBox.length >= 4) {
    ctx.save();
    const rx = offsetX + Math.min(origBox[0], origBox[2]) * renderW;
    const ry = offsetY + Math.min(origBox[1], origBox[3]) * renderH;
    const rw = Math.abs(origBox[2] - origBox[0]) * renderW;
    const rh = Math.abs(origBox[3] - origBox[1]) * renderH;

    ctx.fillStyle = "rgba(56, 189, 248, 0.10)";
    ctx.fillRect(rx, ry, rw, rh);

    ctx.strokeStyle = "rgba(56, 189, 248, 0.85)";
    ctx.lineWidth = 1.8;
    ctx.setLineDash([6, 4]);
    ctx.strokeRect(rx, ry, rw, rh);

    const labelText = "原区域参考";
    ctx.font = "bold 10px sans-serif";
    const txtWidth = ctx.measureText(labelText).width + 12;
    ctx.fillStyle = "rgba(2, 132, 199, 0.90)";
    ctx.fillRect(rx, ry, txtWidth, 18);
    ctx.fillStyle = "#ffffff";
    ctx.fillText(labelText, rx + 6, ry + 13);
    ctx.restore();
  }

  // 2. 确定当前需要高亮显示的区域（拖拽中的新区域，或非标定模式下的当前区域）
  let activeHighlightBox = null;
  if (isDraggingNow) {
    const p1 = drawingState.p1;
    const p2 = drawingState.p2;
    activeHighlightBox = [
      Math.min(p1[0], p2[0]),
      Math.min(p1[1], p2[1]),
      Math.max(p1[0], p2[0]),
      Math.max(p1[1], p2[1]),
    ];
  } else if (!isDrawingActive) {
    activeHighlightBox = origBox;
  }

  if (activeHighlightBox && activeHighlightBox.length >= 4) {
    ctx.save();
    const rx = offsetX + Math.min(activeHighlightBox[0], activeHighlightBox[2]) * renderW;
    const ry = offsetY + Math.min(activeHighlightBox[1], activeHighlightBox[3]) * renderH;
    const rw = Math.abs(activeHighlightBox[2] - activeHighlightBox[0]) * renderW;
    const rh = Math.abs(activeHighlightBox[3] - activeHighlightBox[1]) * renderH;

    const isUnsaved = Boolean(drawingState?.hasUnsavedChanges || parsedZone?._hasUnsaved);

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

      let defaultLabel = "触发区域";
      if (parsedZone && parsedZone.enabled === false) {
        defaultLabel = "触发区域 (未开启检测)";
      }
      const labelText = isUnsaved
        ? "触发区域 (待保存)"
        : defaultLabel;
      ctx.font = "bold 11px sans-serif";
      const txtWidth = ctx.measureText(labelText).width + 16;
      ctx.fillStyle = isUnsaved ? "rgba(234, 88, 12, 0.95)" : "rgba(245, 158, 11, 0.95)";
      ctx.fillRect(rx, ry, txtWidth, 20);
      ctx.fillStyle = "#ffffff";
      ctx.fillText(labelText, rx + 8, ry + 14);
    }
    ctx.restore();
  }

  const activeDetectionBox = isDraggingNow ? activeHighlightBox : origBox;

  const tripwireObj = zoneConfig?.tripwire || zoneConfig?.trigger_line || zoneConfig?.trigger_area;
  if (!isDraggingNow && !activeDetectionBox && zoneConfig && zoneConfig.enabled && tripwireObj && tripwireObj.line) {
    ctx.save();
    const l = tripwireObj.line;
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

    // 仅在标定/触发区域内的目标才画框，标定区域之外的不画框！
    if (!isDetectionInZone(d, parsedZone, activeDetectionBox, rx1, ry1, rx2, ry2)) {
      continue;
    }

    rx1 = Math.max(0, Math.min(1, rx1));
    ry1 = Math.max(0, Math.min(1, ry1));
    rx2 = Math.max(0, Math.min(1, rx2));
    ry2 = Math.max(0, Math.min(1, ry2));

    const bx = offsetX + rx1 * renderW;
    const by = offsetY + ry1 * renderH;
    const bw = Math.max(0, (rx2 - rx1) * renderW);
    const bh = Math.max(0, (ry2 - ry1) * renderH);

    if (bw <= 0 || bh <= 0) continue;

    // 标定触发区域内的目标统一使用绿色框显示
    const mainColor = "#22c55e";

    ctx.strokeStyle = mainColor;
    ctx.lineWidth = 2.0;
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
      const color = "#22c55e";
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
