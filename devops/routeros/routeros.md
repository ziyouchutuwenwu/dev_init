# routeros

## 注意

- 64 位系统下, 用 64 位的 winbox, 否则可能会经常断开连接不上
- 固件不要随意更新，如果当前稳定，就不要更新

## 配置

### 连接

- winbox
- ssh
- 串口

```sh
picocom -b 115200 -s "sb -vv" -v "rb -vv" /dev/ttyUSB0
```

### 重置

```sh
/sy reset
```

### 降级

下载 npk 包

system -> packages, 点击 downgrade
