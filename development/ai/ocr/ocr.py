from paddleocr import PaddleOCR


# 下载地址在 site-packages/paddleocr/paddleocr.py, 然后解压
# 也可以通过 PADDLE_OCR_BASE_DIR 定义
def do_ocr(img):
    det_model_dir = './models/det'
    rec_model_dir = './models/rec'
    cls_model_dir = './models/cls'

    paddle_ocr = PaddleOCR(
            use_angle_cls=True, lang="ch",
            det_model_dir=det_model_dir,
            rec_model_dir=rec_model_dir,
            cls_model_dir=cls_model_dir
        )

    result = paddle_ocr.ocr(img, cls=True)
    return result