# vpn

## 步骤

### 服务器

ipsec 为例

```sh
docker run --restart=always -d \
    --name ipsec-vpn-server \
    -v /lib/modules:/lib/modules:ro \
    -e VPN_USER=vpn \
    -e VPN_PASSWORD=123456 \
    -e VPN_IPSEC_PSK=123456 \
    -p 500:500/udp \
    -p 4500:4500/udp \
    --privileged \
    hwdsl2/ipsec-vpn-server
```

查看信息

```sh
docker logs ipsec-vpn-server
```

### ios

按例子添加即可
