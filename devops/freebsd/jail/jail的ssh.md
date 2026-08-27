# jail 的 ssh

## 步骤

### 创建

创建时自启动ssh服务

```sh
sudo qjail create -4 192.168.88.222 -c demo
sudo qjail config -k demo
```

### 进入 shell

```sh
sudo qjail start demo
sudo qjail console demo
```

### 允许 root 登录

```sh
vi /etc/ssh/sshd_config
PermitRootLogin yes
```

如果创建时没自启动ssh服务

```sh
sysrc -f /etc/rc.conf.local sshd_enable="YES"
service sshd restart
```
