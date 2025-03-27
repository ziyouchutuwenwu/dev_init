import asyncio
import ocr
from robyn import jsonify


# curl --location --request POST 'http://127.0.0.1:8080/ocr' \
# --form 'image=@"/home/mmc/desktop/111.png"'
async def on_ocr(request):
    try:
        if not request.files:
            return jsonify({"error": "no files uploaded"}, status=400)
        if len(request.files) == 0:
            return jsonify({"error": "empty files list"}, status=400)

        file_name = next(iter(request.files))
        img_bin = request.files[file_name]
        # result = ocr.do_ocr(img_bin)
        result = await asyncio.to_thread(ocr.do_ocr, img_bin)
        return jsonify(result)

    except Exception as e:
        return jsonify({"error": str(e)}, status=500)