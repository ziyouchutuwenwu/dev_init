from robyn import Robyn
from ctller.ocr import OCRController


# GTE, POST 等一定要大写
def make(app: Robyn):
    ocr_ctller = OCRController()
    app.add_route("POST", "/ocr1", ocr_ctller.on_ocr1)
    app.add_route("POST", "/ocr2", ocr_ctller.on_ocr2)