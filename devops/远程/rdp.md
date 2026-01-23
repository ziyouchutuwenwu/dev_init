# rdp

## 说明

linux 连接 win 用

## 用法

```sh
# xfreerdp3
# /d:. 代表本地计算机
xfreerdp /v:10.0.2.135 \
  /u:administrator \
  /p:123456 \
  /cert:ignore \
  /size:1024x600 \
  /auto-reconnect
```
