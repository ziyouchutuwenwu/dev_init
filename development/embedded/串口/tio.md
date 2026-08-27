# tio

## 说明

用户只要在特定组下，就可以直接访问

debian, voidlinux 是 dialout

manjaro 是 uucp

## 用法

串口列表

```sh
tio --list
```

基础用法

```sh
tio -b 115200 /dev/ttyUSB0
# 退出
c-t q
```

log

```sh
tio --log-file tio.log --log /dev/ttyUSB0
```

16 进制显示

```sh
tio --output-mode hex /dev/ttyUSB0
```

回车转换为 \r\n

```sh
# at 模块的标准
tio --map ONLCRNL,ICRNL /dev/ttyUSB0
```
