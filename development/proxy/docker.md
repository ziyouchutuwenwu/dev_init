# docker

## 说明

pull 模式下，sv 和 system 略有不同

## pull

### systemd

创建代理配置文件

```sh
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo vim /etc/systemd/system/docker.service.d/proxy.conf
```

不支持 socks5, 必须用 http 代理

```sh
[Service]
Environment="HTTP_PROXY=http://10.0.2.1:8118"
Environment="HTTPS_PROXY=http://10.0.2.1:8118"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.2.1"
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

### sv

```sh
echo "$HTTP_PROXY"   | tee /etc/sv/docker/env/HTTP_PROXY
echo "$HTTPS_PROXY"  | tee /etc/sv/docker/env/HTTPS_PROXY
echo "$NO_PROXY"     | tee /etc/sv/docker/env/NO_PROXY

sv restart docker
```

## 容器实例

注意，实例不能用 `127.0.0.1` 这个 ip, 得用主机的真实 ip

```sh
mkdir -p ~/.docker
vim ~/.docker/config.json
```

```json
{
  "proxies": {
    "default": {
      "httpProxy": "socks5://10.0.2.1:1080",
      "httpsProxy": "socks5://10.0.2.1:1080",
      "noProxy": "localhost,127.0.0.1,10.0.2.1"
    }
  }
}
```

测试

```sh
docker exec -it xxx /bin/sh
curl --head xxx.com
```

## build

```sh
docker build . \
    --build-arg "HTTP_PROXY=socks5://10.0.2.1:1080" \
    --build-arg "HTTPS_PROXY=socks5://10.0.2.1:1080" \
    --build-arg "NO_PROXY=localhost,127.0.0.1,10.0.2.1" \
    -t your/image:tag
```
