# 说明

## 用法

### 手动启动

调试模式

```sh
uvicorn main:app --reload
```

允许所有 ip

```sh
uvicorn main:app --host 0.0.0.0 --port 8000
```

### docker

```sh
docker build -t broken_json_parser ./ --no-cache
```

```sh
docker run --restart=always -d --name broken-json-parser -p 8181:80 \
-v /etc/localtime:/etc/localtime \
-e TZ=Asia/Shanghai \
--privileged=true broken_json_parser
```
