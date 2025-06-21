# readme

## 说明

更换模型即可实现

人脸识别或者物体识别

## 运行

服务端

```sh
uv sync
uv run main.py --port=8080
```

客户端

```sh
curl -X POST --data-binary @"$HOME/desktop/11.png" http://localhost:8080/detect
```
