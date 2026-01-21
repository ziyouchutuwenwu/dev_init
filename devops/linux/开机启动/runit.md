# runit

## 说明

voidlinux 自带

## 例子

### 目录结构

```sh
/etc/sv/xxx/
```

```sh
run 启动脚本
log 日志目录

# cat /etc/sv/docker/env/HTTP_PROXY
# http://127.0.0.1:8118
env 环境变量目录
```

```sh
# 设置开机自启
ln -s /etc/sv/xxx /var/service/
sv status privoxy
sv log privoxy
sv restart privoxy
```
