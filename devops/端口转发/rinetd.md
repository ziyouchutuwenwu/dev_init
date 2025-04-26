# rinetd

## 说明

用于端口转发

## 用法

启动服务

```sh
python -m http.server
```

配置文件

```sh
/etc/rinetd.conf
```

```conf
allow *.*.*.*
# 给外部访问的ip   外部访问的端口    实际 ip    实际端口
0.0.0.0          8888            0.0.0.0   8000
```

运行

```sh
pkill rinetd; rinetd -c /etc/rinetd.conf -f
```
