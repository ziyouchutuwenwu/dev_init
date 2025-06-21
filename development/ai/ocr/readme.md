# readme

## 运行

```sh
uv sync
ln -s ~/.paddlex ./data
uv run main.py --port=8888
```

## 测试

```sh
curl -X POST --data-binary @"$HOME/desktop/11.png" http://localhost:8888/ocr1
curl -X POST -F "111.png=@$HOME/desktop/11.png" http://localhost:8888/ocr2
```
