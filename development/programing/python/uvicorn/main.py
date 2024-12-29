from fastapi import FastAPI
from routes import json_parser

app = FastAPI()
app.include_router(json_parser.router, prefix='/api')