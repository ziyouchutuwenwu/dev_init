# mgraftcp

## 说明

支持代理 tcp，不支持代理 udp

[官网地址](https://github.com/hmgle/graftcp)

## 用法

```sh
# --http_proxy 模式似乎有 bug
alias proxy='mgraftcp --socks5="127.0.0.1:1080"'
```

测试

```sh
proxy curl https://ipinfo.io/ip
```
