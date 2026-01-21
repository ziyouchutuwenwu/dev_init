# rc-local

## 说明

都是 systemd 模拟，/etc/profile 默认不会加载

manjaro 下默认 type 为 idle

## 例子

```sh
/usr/local/lib/systemd/system/rc-local.service
```

```sh
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

/etc/rc.local

```sh
#!/bin/sh -e

. /etc/profile

# nohup xxx > /dev/null 2>&1 &
# screen -dm xxx

/opt/demo/_build/prod/rel/demo/bin/demo daemon

exit 0
```

然后

```sh
chmod a+x /etc/rc.local
systemctl enable rc-local --now
```
