from robyn import Robyn
import ctllers


# GTE, POST 等一定要大写
def make(app: Robyn):
    app.add_route("POST", "/ocr", ctllers.on_ocr)