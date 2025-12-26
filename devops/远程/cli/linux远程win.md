# linux 远程 win

## 说明

也是 ssh

## 步骤

### 安装

下载 msi 格式的 sshd，手动安装

### 启动

```sh
netsh advfirewall set allprofiles state off

net user runner 123456 /add
net localgroup Administrators runner /add
```
