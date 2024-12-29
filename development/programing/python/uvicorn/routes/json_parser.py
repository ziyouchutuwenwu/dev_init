from fastapi import APIRouter
import demjson

router = APIRouter()

@router.post("/json", tags=["非标 json 解析"])
async def parse_json(data: str):
    return demjson.decode(data)