# frp

地址在 [这里](https://github.com/fatedier/frp)

## 配置

### vps 上

frps.ini

```ini
[common]
bind_port = 7890
# bind_udp_port = 7890
token = 9d7aeb67ba01
```

启动

```sh
./frps -c frps.ini
```

### 内网主机

frpc.ini

```ini
[common]
server_addr = 服务器公网 IP
server_port = 7890
token = 9d7aeb67ba01

[abc]
type = tcp
local_ip = 127.0.0.1
local_port = 8888
remote_port = 12316
```

```sh
./frpc -c frpc.ini
```
