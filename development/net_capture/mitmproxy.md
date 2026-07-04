# mitmproxy

## 说明

作为代理启动，同时可以抓包

## 步骤

### 启动代理

三选一

```sh
mitmproxy
mitmdump
mitmweb
```

### 启动客户端

客户端配置好代理服务器启动，手机端一样

```sh
google-chrome-stable --proxy-server=http://127.0.0.1:8080 --ignore-certificate-errors
```

### 安装证书

```sh
http://mitm.it/
```
