import detect  # 你写的 detect.py
import json
import numpy as np
import cv2

def make(app):
    @app.post("/detect")
    async def detect_raw_image(request):
        try:
            # ✅ 修复这里：从 request.body 读取图像数据
            img_bytes = request.body

            # 转成 OpenCV 图像
            np_arr = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            # 检测
            results = detect.detect_from_image(img)

            return {
                "status_code": 200,
                "body": json.dumps(results)
            }

        except Exception as e:
            return {
                "status_code": 500,
                "body": f"Server error: {str(e)}"
            }
