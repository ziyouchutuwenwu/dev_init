# livebook

## 用法

安装

```sh
docker run -d --name livebook --rm \
  -p 8080:8080 \
  -p 8081:8081 \
  --pull always \
  ghcr.io/livebook-dev/livebook
```

或者

```sh
docker run -d --name livebook --rm \
  -e HTTP_PROXY=http://192.168.0.233:8118 \
  -e HTTPS_PROXY=http://192.168.0.233:8118 \
  -p 8080:8080 \
  -p 8081:8081 \
  --pull always \
  ghcr.io/livebook-dev/livebook
```