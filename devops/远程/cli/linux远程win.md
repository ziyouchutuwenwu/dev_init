# linux 远程 win

## 步骤

### 安装

[下载地址](https://github.com/PowerShell/Win32-OpenSSH/releases/)

### 备忘

关闭防火墙

```sh
netsh advfirewall set allprofiles state off
```

改密码

```sh
net user xxx 123456
```

查看所在 group

```sh
net user xxx
```

创建用户

```sh
net user runner 123456 /add
net localgroup Administrators runner /add
```
