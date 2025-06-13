import time
import logging
from robyn import jsonify
from service.ocr import OCRService
import numpy as np

class OCRController:
    def __init__(self):
        self.ocr_service = OCRService()

    def on_ocr1(self, request):
        try:
            start_time = time.time()
            img_bin = bytes(request.body)
            if not img_bin:
                return jsonify({"error": "no binary uploaded"}), {}, 400

            result = self.ocr_service.do_ocr(img_bin)
            # 处理不可序列化的 numpy 类型
            def safe(obj):
                if isinstance(obj, np.ndarray):
                    return obj.tolist()
                if isinstance(obj, bytes):
                    return obj.decode(errors='ignore')
                return obj
            def walk(obj):
                if isinstance(obj, dict):
                    return {k: walk(v) for k, v in obj.items()}
                if isinstance(obj, list):
                    return [walk(i) for i in obj]
                return safe(obj)
            result = walk(result)
            end_time = time.time()
            logging.info(f"ocr time: {end_time - start_time:.4f} seconds")
            return jsonify(result)

        except Exception as e:
            return jsonify({"error": str(e)}), {}, 500


    def on_ocr2(self, request):
        try:
            start_time = time.time()
            if not request.files:
                return jsonify({"error": "no files uploaded"}), {}, 400
            if len(request.files) == 0:
                return jsonify({"error": "empty files list"}), {}, 400
            file_name = next(iter(request.files))
            img_bin = request.files[file_name]

            result = self.ocr_service.do_ocr(img_bin)
            # 处理不可序列化的 numpy 类型
            def safe(obj):
                if isinstance(obj, np.ndarray):
                    return obj.tolist()
                if isinstance(obj, bytes):
                    return obj.decode(errors='ignore')
                return obj
            def walk(obj):
                if isinstance(obj, dict):
                    return {k: walk(v) for k, v in obj.items()}
                if isinstance(obj, list):
                    return [walk(i) for i in obj]
                return safe(obj)
            result = walk(result)
            end_time = time.time()
            logging.info(f"ocr time: {end_time - start_time:.4f} seconds")
            return jsonify(result)

        except Exception as e:
            return jsonify({"error": str(e)}), {}, 500