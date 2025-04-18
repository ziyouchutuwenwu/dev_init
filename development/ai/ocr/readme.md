# readme

## 说明

第一次客户端请求的时候，会自动下载模型

## 依赖库

注意库的版本，具体看官网

```sh
robyn
paddlepaddle
paddleocr
```

## 测试

```sh
curl -X POST --data-binary @"/desktop/111.png" http://localhost:8888/ocr1
curl -X POST -F "111.png=@/desktop/111.png" http://localhost:8888/ocr2
```
