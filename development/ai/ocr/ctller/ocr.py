import time
from robyn import jsonify
from service.ocr import OCRService

class OCRController:
    def __init__(self):
        self.ocr_service = OCRService()

    def on_ocr(self, request):
        try:
            start_time = time.time()
            if not request.files:
                return jsonify({"error": "no files uploaded"}, status=400)
            if len(request.files) == 0:
                return jsonify({"error": "empty files list"}, status=400)

            file_name = next(iter(request.files))
            img_bin = request.files[file_name]
            result = self.ocr_service.do_ocr(img_bin)
            end_time = time.time()
            print(f"ocr time: {end_time - start_time:.4f} seconds")
            return jsonify(result)

        except Exception as e:
            return jsonify({"error": str(e)}, status=500)