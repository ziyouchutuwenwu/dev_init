import numpy as np
import cv2
from paddleocr import PaddleOCR
import os

class OCRService:
    def __init__(self):
        if not hasattr(self, "engine"):
            self.engine = PaddleOCR(
                use_angle_cls=True,
                lang="ch"
            )

    # img_path 和 img_bin 都支持
    def do_ocr(self, img_bin):
        # 将二进制图片转为 numpy.ndarray
        img_array = np.frombuffer(img_bin, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        return self.engine.predict(img)
