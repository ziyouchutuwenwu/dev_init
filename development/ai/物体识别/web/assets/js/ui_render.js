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
        const [bx1, by1, bx2, by2] = d.box;
        if (bx1 <= 1.0 && by1 <= 1.0 && bx2 <= 1.0 && by2 <= 1.0 && (bx2 > 0 || by2 > 0)) {
          x1 = bx1;
          y1 = by1;
          x2 = bx2;
          y2 = by2;
        } else {
          const bw = (d.frame_width && d.frame_width > 0) ? d.frame_width : 1920;
          const bh = (d.frame_height && d.frame_height > 0) ? d.frame_height : 1080;
          x1 = bx1 / bw;
          y1 = by1 / bh;
          x2 = bx2 / bw;
          y2 = by2 / bh;
        }
      }
    }

    if (x1 !== null && y1 !== null && x2 !== null && y2 !== null) {
      cx = (x1 + x2) / 2;
      cy = (y1 + y2) / 2;
    } else if (d.center && Array.isArray(d.center) && d.center.length >= 2) {
      cx = d.center[0];
      cy = d.center[1];
      if (cx > 1.0 || cy > 1.0) {
        const bw = (d.frame_width && d.frame_width > 0) ? d.frame_width : 1920;
        const bh = (d.frame_height && d.frame_height > 0) ? d.frame_height : 1080;
        cx = cx / bw;
        cy = cy / bh;
      }
    }

    if (cx !== null && cy !== null) {
      return cx >= minX && cx <= maxX && cy >= minY && cy <= maxY;
    }

    return false;
  }

  if (cfg?.roi?.type === "polygon" && Array.isArray(cfg.roi.coords)) {
    const pts = cfg.roi.coords;
    let cx = null, cy = null;
    let x1 = rx1, y1 = ry1, x2 = rx2, y2 = ry2;
    if (x1 === null || y1 === null || x2 === null || y2 === null) {
      if (d.rel_box && Array.isArray(d.rel_box) && d.rel_box.length >= 4) {
        [x1, y1, x2, y2] = d.rel_box;
      } else if (d.box && Array.isArray(d.box) && d.box.length >= 4) {
        const [bx1, by1, bx2, by2] = d.box;
        if (bx1 <= 1.0 && by1 <= 1.0 && bx2 <= 1.0 && by2 <= 1.0 && (bx2 > 0 || by2 > 0)) {
          x1 = bx1;
          y1 = by1;
          x2 = bx2;
          y2 = by2;
        } else {
          const bw = (d.frame_width && d.frame_width > 0) ? d.frame_width : 1920;
          const bh = (d.frame_height && d.frame_height > 0) ? d.frame_height : 1080;
          x1 = bx1 / bw;
          y1 = by1 / bh;
          x2 = bx2 / bw;
          y2 = by2 / bh;
        }
      }
    }
    if (x1 !== null && y1 !== null && x2 !== null && y2 !== null) {
      cx = (x1 + x2) / 2;
      cy = (y1 + y2) / 2;
    } else if (d.center && Array.isArray(d.center) && d.center.length >= 2) {
      cx = d.center[0];
      cy = d.center[1];
      if (cx > 1.0 || cy > 1.0) {
        const bw = (d.frame_width && d.frame_width > 0) ? d.frame_width : 1920;
        const bh = (d.frame_height && d.frame_height > 0) ? d.frame_height : 1080;
        cx = cx / bw;
        cy = cy / bh;
      }
    }
    if (cx !== null && cy !== null) {
      return isPointInPolygon(cx, cy, pts);
    }
    return false;
  }

  if (d.in_roi !== undefined || d.triggered !== undefined || d.crossed !== undefined) {
    return Boolean(d.in_roi || d.triggered || d.crossed);
  }

  return true;
}

export function getSelectedClassesFromDom(canvas, video) {
  const card = canvas?.closest(".stream-card") || video?.closest(".stream-card");
  if (card && card.dataset.selectedClasses) {
    try {
      const parsed = JSON.parse(card.dataset.selectedClasses);
      if (Array.isArray(parsed)) return parsed;
    } catch (e) {}
  }
  const grid = document.getElementById("stream-cards-grid");
  if (grid && grid.dataset.selectedClasses) {
    try {
      const parsed = JSON.parse(grid.dataset.selectedClasses);
      if (Array.isArray(parsed)) return parsed;
    } catch (e) {}
  }
  return null;
}

export const TARGET_CLASS_ALIASES = {};

export function getLabelDisplayName(label) {
  if (!label) return "";
  const dict = window.LABEL_TRANSLATIONS;
  return dict?.[label] || dict?.[label.toLowerCase().trim()] || label;
}

export function isDetectionTargetMatched(d, targetClasses) {
  if (!d) return false;
  if (!targetClasses || !Array.isArray(targetClasses) || targetClasses.length === 0) return false;

  const label = (d.label || "").toString().toLowerCase().trim();
  const displayLabel = getLabelDisplayName(label).toLowerCase();
  const alertType = (d.alert_type || "").toString().toLowerCase().trim();
  const displayAlert = getLabelDisplayName(alertType).toLowerCase();
  const ruleName = (d.rule_name || "").toString().toLowerCase().trim();
  const ruleId = (d.rule_id || "").toString().toLowerCase().trim();

  for (const tc of targetClasses) {
    if (!tc) continue;
    const target = tc.toString().toLowerCase().trim();
    const displayTarget = getLabelDisplayName(target).toLowerCase();

    if (label && (label === target || displayLabel === target || label === displayTarget || displayLabel === displayTarget)) return true;
    if (alertType && (alertType === target || displayAlert === target || alertType === displayTarget || displayAlert === displayTarget)) return true;
    if (ruleName && (ruleName === target || ruleName === displayTarget || ruleName.includes(target) || target.includes(ruleName))) return true;
    if (ruleId && (ruleId === target || ruleId.includes(target))) return true;
  }

  return false;
}

export function drawDetections(canvas, video, detections, frameW, frameH, zoneConfig = null, drawingState = null, isConnected = null, isDetectionActive = null) {
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
  const targetClasses = (parsedZone && Array.isArray(parsedZone.target_classes))
    ? parsedZone.target_classes
    : getSelectedClassesFromDom(canvas, video);

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
        defaultLabel = "触发区域 (检测未启用)";
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

  const canDraw =
    (isConnected === null || isConnected === undefined || isConnected) &&
    (isDetectionActive === null || isDetectionActive === undefined || isDetectionActive) &&
    (!parsedZone || parsedZone.enabled !== false);

  if (!canDraw || !detections || detections.length === 0) return;

  const intrinsicW = (video && video.videoWidth) || frameW || 1920;
  const intrinsicH = (video && video.videoHeight) || frameH || 1080;

  ctx.lineWidth = 2.0;
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

    if (!isDetectionTargetMatched(d, targetClasses)) {
      continue;
    }

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

    const boxColor = "#4ade80";

    ctx.strokeStyle = boxColor;
    ctx.lineWidth = 2.0;
    ctx.strokeRect(bx, by, bw, bh);

    const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
    const trackPrefix = (d.track_id !== undefined && d.track_id !== null) ? `ID:#${d.track_id} ` : "";
    const rawLabel = d.label || ("class_" + d.class_id);
    const displayLabel = getLabelDisplayName(rawLabel);
    const textExtra = (d.text && typeof d.text === "string" && d.text.trim())
      ? ` [${d.text.trim()}]`
      : ((d.plate_text && typeof d.plate_text === "string" && d.plate_text.trim()) ? ` [${d.plate_text.trim()}]` : "");
    const alertPrefix = (d.alert_type && d.alert_type !== d.label && d.alert_type !== "person" && d.alert_type !== "人员目标" && d.alert_type !== "target_detected")
      ? `[${d.alert_type}] `
      : "";
    const labelText = alertPrefix + trackPrefix + displayLabel + textExtra + (confStr ? " " + confStr : "");
    const textWidth = ctx.measureText(labelText).width + 8;
    const labelHeight = 18;

    ctx.fillStyle = boxColor;
    ctx.fillRect(bx, by - labelHeight >= 0 ? by - labelHeight : by, textWidth, labelHeight);

    ctx.fillStyle = "#0f291e";
    ctx.fillText(labelText, bx + 4, (by - labelHeight >= 0 ? by - labelHeight : by) + 13);

    // 绘制姿态估计关节点与骨骼连线
    if (d.keypoints && Array.isArray(d.keypoints) && d.keypoints.length >= 3) {
      const baseW = frameW || intrinsicW;
      const baseH = frameH || intrinsicH;
      if (baseW > 0 && baseH > 0) {
        const kpts = [];
        for (let i = 0; i + 2 < d.keypoints.length; i += 3) {
          const kx = offsetX + (d.keypoints[i] / baseW) * renderW;
          const ky = offsetY + (d.keypoints[i + 1] / baseH) * renderH;
          const score = d.keypoints[i + 2];
          kpts.push({ x: kx, y: ky, score: score });
        }

        const SKELETON = [
          [0, 1], [0, 2], [1, 3], [2, 4],
          [5, 6], [5, 7], [7, 9], [6, 8], [8, 10],
          [5, 11], [6, 12], [11, 12],
          [11, 13], [13, 15], [12, 14], [14, 16]
        ];
        ctx.strokeStyle = "rgba(56, 189, 248, 0.85)";
        ctx.lineWidth = 2.0;
        for (const [p1, p2] of SKELETON) {
          if (p1 < kpts.length && p2 < kpts.length) {
            if (kpts[p1].score > 0.25 && kpts[p2].score > 0.25) {
              ctx.beginPath();
              ctx.moveTo(kpts[p1].x, kpts[p1].y);
              ctx.lineTo(kpts[p2].x, kpts[p2].y);
              ctx.stroke();
            }
          }
        }

        for (const pt of kpts) {
          if (pt.score > 0.25) {
            ctx.beginPath();
            ctx.arc(pt.x, pt.y, 3.5, 0, 2 * Math.PI);
            ctx.fillStyle = "#facc15";
            ctx.fill();
            ctx.strokeStyle = "#000000";
            ctx.lineWidth = 1.0;
            ctx.stroke();
          }
        }
      }
    }
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

  const hasPlaceholder =
    listEl.dataset.emptyState !== "false" ||
    (listEl.firstElementChild && listEl.firstElementChild.classList.contains("text-zinc-400")) ||
    listEl.textContent.includes("暂无目标");

  if (hasPlaceholder) {
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

      if (!left || !dot || !text || !right) {
        li.innerHTML = "";
        li.className =
          "flex items-center justify-between rounded border border-zinc-100 bg-zinc-50 px-2.5 py-1.5 text-xs";
        const newLeft = document.createElement("span");
        newLeft.className = "font-medium text-zinc-800 flex items-center gap-1.5";

        dot = document.createElement("span");
        dot.className = "w-2.5 h-2.5 rounded-full inline-block";
        newLeft.appendChild(dot);

        text = document.createElement("span");
        newLeft.appendChild(text);

        right = document.createElement("span");
        right.className = "font-mono text-zinc-500 text-xs";
        li.append(newLeft, right);
      }
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
      if (dot.style.backgroundColor !== "#4ade80") {
        dot.style.backgroundColor = "#4ade80";
      }
    }

    if (text) {
      const trackStr = (d.track_id !== undefined && d.track_id !== null) ? `[#${d.track_id}] ` : "";
      const rawLabel = d.label || ("class_" + d.class_id);
      const displayLabel = getLabelDisplayName(rawLabel);
      const alertPrefix = (d.alert_type && d.alert_type !== d.label && d.alert_type !== "person" && d.alert_type !== "人员目标" && d.alert_type !== "target_detected")
        ? `[${d.alert_type}] `
        : "";
      const textExtra = (d.text && typeof d.text === "string" && d.text.trim())
        ? ` [${d.text.trim()}]`
        : ((d.plate_text && typeof d.plate_text === "string" && d.plate_text.trim()) ? ` [${d.plate_text.trim()}]` : "");
      const labelVal = alertPrefix + trackStr + displayLabel + textExtra;
      if (text.textContent !== labelVal) {
        text.textContent = labelVal;
      }
      text.className = "font-medium text-zinc-800";
    }

    if (right) {
      const confStr = d.confidence !== undefined ? (Number(d.confidence) * 100).toFixed(0) + "%" : "";
      let coordStr = "";
      if (d.rel_box && Array.isArray(d.rel_box)) {
        coordStr = "[" + d.rel_box.map((v) => (v * 100).toFixed(0) + "%").join(",") + "]";
      } else if (d.box && Array.isArray(d.box)) {
        coordStr = "[" + d.box.join(",") + "]";
      }
      const rightVal = confStr + (coordStr ? " " + coordStr : "");
      if (right.textContent !== rightVal) {
        right.textContent = rightVal;
      }
    }
  }
}
