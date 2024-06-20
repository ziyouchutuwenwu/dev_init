# git

## 两种方式

### 环境变量

推荐

```sh
export http_proxy=socks5://127.0.0.1:1080
export https_proxy=socks5://127.0.0.1:1080
```

### 配置文件

设置

```sh
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

取消

```sh
git config --global --unset http.proxy
git config --global --unset https.proxy
```
