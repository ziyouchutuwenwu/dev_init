import time
import logging
from robyn import jsonify
from service.ocr import OCRService

class OCRController:
    def __init__(self):
        self.ocr_service = OCRService()

    def on_ocr(self, request):
        try:
            start_time = time.time()
            img_bin = bytes(request.body)
            if not img_bin:
                return jsonify({"error": "no binary uploaded"}, status=400)

            result = self.ocr_service.do_ocr(img_bin)
            end_time = time.time()
            logging.info(f"ocr time: {end_time - start_time:.4f} seconds")
            return jsonify(result)

        except Exception as e:
            return jsonify({"error": str(e)}, status=500)