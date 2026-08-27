# vnc

## 说明

linux 为服务端

### 安装

```sh
sudo pacman -S x11vnc
sudo apt install x11vnc -y
```

### 服务

```sh
/usr/local/lib/systemd/system/vnc.service
```

```ini
[Unit]
Description=vnc
After=multi-user.target

[Service]
Type=simple
# ExecStart=x11vnc -auth guess -forever -loop -noxdamage -scale 0.9x0.9 -passwd 90909090 -repeat -shared -o /var/log/x11vnc.log
ExecStart=x11vnc -auth guess -forever -noxdamage -scale 0.9x0.9 -passwd 90909090

[Install]
WantedBy=multi-user.target
```

### 开机启动

```sh
systemctl enable vnc --now
```
