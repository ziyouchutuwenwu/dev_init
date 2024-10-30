# livebook

## 用法

安装

```sh
docker run -d --name livebook --rm \
  -e HTTP_PROXY=http://10.0.2.1:8118 \
  -e HTTPS_PROXY=http://10.0.2.1:8118 \
  -p 8080:8080 \
  -p 8081:8081 \
  --pull always \
  ghcr.io/livebook-dev/livebook
```
