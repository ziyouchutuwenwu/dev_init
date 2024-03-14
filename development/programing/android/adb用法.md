# adb 用法

## 用法

### 无线连接

临时

```sh
adb tcpip 5555
adb connect 192.168.88.18
```

无线连接

```sh
mount -o rw,remount /system
echo service.adb.tcp.port=5555 >> /system/build.prop
adb connect 192.168.88.18
```
