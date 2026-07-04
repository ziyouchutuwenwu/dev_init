# udev

## 说明

用于配置外接设备的访问权限

串口设备一般属于 dialout/uucp 组，用户在这个组里面就可以了

## 用法

### 检查

```sh
lsusb

# 1111 为 idVendor
# 2222 为 idProduct
Bus 001 Device 002: ID 1111:2222 xxx device
```

```sh
cd /etc/udev/rules.d/
```

demo.rules

```sh
SUBSYSTEM=="usb", ATTR{idVendor}=="1111", ATTR{idProduct}=="2222", MODE="0666"
```

刷新

```sh
udevadm control --reload-rules
udevadm trigger
```
