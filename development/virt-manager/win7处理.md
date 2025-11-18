# win7 处理

## 安装

必须在物理机上安装这个，否则无法安装 win7 虚拟机

```sh
pacman -S virtio-win
```

## smb 共享

```sh
安装 smb 客户端
net use z: \\192.168.56.1\smb
net use * /del /y
```
