# frp

地址在 [这里](https://github.com/fatedier/frp)

## 说明

需要公网 vps

## 配置

### vps 配置

frps.toml

```toml
bindPort = 6000
```

启动

```sh
frps -c frps.toml
```

### 内网配置

frpc.toml

```toml
serverAddr = "x.x.x.x"
serverPort = 7000

serverAddr = "127.0.0.1"
serverPort = 7000

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000

[[proxies]]
name = "web1"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8000
remotePort = 9000
```

启动

```sh
frpc -c frpc.ini
```

### 测试

```sh
ssh -p 6000 xxx@xx.xx.xx.xx
curl http://xx.xx.xx.xx:9000
```
