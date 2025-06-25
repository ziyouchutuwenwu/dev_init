# serveo

## 说明

不需要公网 ip, 但是需要访问 serveo.net

## 用法

### ssh

```sh
autossh -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" -R 0:localhost:22 serveo.net
```

客户端访问

```sh
ssh -p 45678 xxx@serveo.net
```

### http

转发本地 http, 访问的时候为 https

```sh
ssh -R 80:localhost:8000 serveo.net
```
