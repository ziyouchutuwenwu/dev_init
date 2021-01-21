# freebsd 安装桌面

## 步骤

安装 sudo

```sh
pkg install -y sudo
pw groupmod wheel -m <username>

visudo, 添加
%wheel ALL=(ALL) NOPASSWD: ALL
```

安装需要的包

```sh
sudo pkg install -y xorg slim xfce
```

sudo vim /etc/rc.conf

```sh
moused_enable="YES"mmc
dbus_enable="YES"
hald_enable="YES"
slim_enable="YES"
```

vim ~/.xinitrc

```sh
exec  xfce4-session
```

## 中文支持

```sh
chsh -s /bin/csh
```

sudo vim /etc/csh.cshrc

```sh
setenv LANG     zh_CN.UTF-8
setenv LC_CTYPE zh_CN.UTF-8
setenv LC_ALL   zh_CN.UTF-8
```
