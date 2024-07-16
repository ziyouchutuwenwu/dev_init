# docker

## pull 代理

创建代理配置文件

```sh
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo vim /etc/systemd/system/docker.service.d/proxy.conf
```

不支持 socks5, 必须用 http 代理

```sh
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:8118"
Environment="HTTPS_PROXY=http://127.0.0.1:8118"
Environment="NO_PROXY=localhost,127.0.0.1, 10.0.2."
```

重启

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker
```

检查

```sh
systemctl show --property=Environment docker
```

## 容器实例代理

注意，实例不能用 `127.0.0.1` 这个 ip, 得用主机的真实 ip

```sh
mkdir -p ~/.docker
vim ~/.docker/config.json
```

```json
{
  "proxies": {
    "default": {
      "httpProxy": "socks5://192.168.88.96:1080",
      "httpsProxy": "socks5://192.168.88.96:1080",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}
```

测试

```sh
docker exec -it xxx /bin/sh
curl --head xxx.com
```

## build 设置代理

```sh
docker build . \
    --build-arg "http_proxy=socks5://192.168.88.96:1080" \
    --build-arg "https_proxy=socks5://192.168.88.96:1080" \
    --build-arg "NO_PROXY=localhost,127.0.0.1" \
    -t your/image:tag
```
