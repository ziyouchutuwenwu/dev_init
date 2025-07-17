import numpy as np
from ultralytics import YOLO

# model = YOLO("models/yolov8n.pt")
model = YOLO("models/yolov8n-face.pt")

def detect_from_image(img_np: np.ndarray):
    """
    直接从图像数组进行目标检测
    """
    results = model(img_np)

    detections = []
    for r in results:
        for box in r.boxes:
            cls_id = int(box.cls[0].item())
            conf = float(box.conf[0].item())
            xyxy = [float(v) for v in box.xyxy[0].tolist()]
            detections.append({
                "class_id": cls_id,
                "confidence": conf,
                "bbox": xyxy
            })
    return detections
