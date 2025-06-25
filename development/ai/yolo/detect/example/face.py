from ultralytics import YOLO

# 手动下载模型 https://github.com/akanametov/yolo-face/releases
model = YOLO("models/yolov8n-face.pt")

results = model("11.png", save=True)

# 3. 查看预测框等信息
for r in results:
    boxes = r.boxes
    # 检测框 [x1, y1, x2, y2]
    print(boxes.xyxy)
    # 置信度
    print(boxes.conf)
    # 类别ID
    print(boxes.cls)