# rc-local

## 说明

适用于 debian, freebsd, manjaro

debian 和 manjaro 都是 systemd 模拟的

manjaro 下默认 type 为 idle

```sh
# /usr/local/lib/systemd/system/rc-local.service
[Unit]
Description=rc.local
ConditionPathExists=/etc/rc.local
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```sh
#!/bin/sh -e

# nohup xxx > /dev/null 2>&1 &
# screen -dm xxx

/opt/demo/_build/prod/rel/demo/bin/demo daemon

exit 0
```

然后

```sh
sudo chmod +x /etc/rc.local
sudo systemctl enable rc-local --now
```
