from ultralytics import YOLO

# 自动下载 https://github.com/ultralytics/assets/releases/download/v8.3.0/yolov8n.pt
model = YOLO("models/yolov8n.pt")

results = model("11.png", save=True)

for r in results:
    boxes = r.boxes
    # 检测框 [x1, y1, x2, y2]
    print(boxes.xyxy)
    # 置信度
    print(boxes.conf)
    # 类别ID
    print(boxes.cls)