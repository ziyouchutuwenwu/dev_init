# linux 远程 win

## 步骤

### 安装

[下载地址](https://github.com/PowerShell/Win32-OpenSSH/releases/)

### 启动

```sh
# 关闭防火墙
netsh advfirewall set allprofiles state off
```

```sh
# 改密码
net user xxx 123456

# 查看 group
net user xxx
```

```sh
# 创建用户
net user runner 123456 /add
net localgroup Administrators runner /add
```
