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

    # img_path 和 img_bin 都支持
    def do_ocr(self, img_bin):
        return self.engine.ocr(img_bin, cls=True)
