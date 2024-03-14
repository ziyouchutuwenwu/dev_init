# curl

## 两种方式

### 环境变量

推荐

```sh
export http_proxy=socks5://127.0.0.1:1080
export https_proxy=socks5://127.0.0.1:1080
```

### 配置文件

```sh
vim ~/.curlrc
```

```sh
proxy=socks5://127.0.0.1:1080
```
