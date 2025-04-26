# frp

地址在 [这里](https://github.com/fatedier/frp)

## 说明

需要公网 vps

域名，ssl 全部需要自己处理

## 配置

### vps 配置

frps.ini

```ini
[common]
bind_port = 7890
# bind_udp_port = 7890
token = 123456
```

启动

```sh
frps -c frps.ini
```

### 内网配置

frpc.ini

```ini
[common]
server_addr = $VPS_IP
server_port = 7890
# protocol = udp
token = 123456

# 任意名字
[abc]
type = tcp
local_ip = 127.0.0.1
local_port = 8888
remote_port = 12316
```

启动

```sh
frpc -c frpc.ini
```

### 测试

```sh
curl http://$VPS_IP:12316
```
