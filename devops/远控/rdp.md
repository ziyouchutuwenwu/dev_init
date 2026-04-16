# rdp

## 说明

win 开 3389

## 用法

固定分辨率

```sh
# xfreerdp3
xfreerdp /v:10.0.2.135:3389 /u:administrator /p:123456 /cert:ignore /size:1024x600 /gfx /clipboard /auto-reconnect
```

自动缩放

```sh
# xfreerdp3
xfreerdp /v:10.0.2.135:3389 /u:administrator /p:123456 /cert:ignore /dynamic-resolution /gfx /clipboard /auto-reconnect
```
