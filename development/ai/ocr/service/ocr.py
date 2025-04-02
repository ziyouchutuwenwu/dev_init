from paddleocr import PaddleOCR

class OCRService:
    def __init__(self):
        if not hasattr(self, "engine"):
            self.engine = PaddleOCR(
                det_model_dir='./models/det',
                rec_model_dir='./models/rec',
                cls_model_dir='./models/cls',
                use_angle_cls=True,
                lang="ch",
                use_gpu=True,
                show_log=False
            )


    def do_ocr(self, img):
        return self.engine.ocr(img, cls=True)