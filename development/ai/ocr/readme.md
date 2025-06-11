# readme

## 说明

启动的时候，会自动下载模型

## 运行

```sh
uv sync
uv run main.py --port=8888
```

## 测试

```sh
curl -X POST --data-binary @"$HOME/desktop/111.png" http://localhost:8888/ocr1
curl -X POST -F "111.png=@$HOME/desktop/111.png" http://localhost:8888/ocr2
```
