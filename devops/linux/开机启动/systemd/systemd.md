# systemd

## 说明

默认用户为 root

| type    | 说明                                               |
| ------- | -------------------------------------------------- |
| simple  | 在前台运行的服务                                   |
| forking | 在后台运行的服务                                   |
| idle    | 等其它非 idle 的服务启动完以后，再启动，在前台运行 |
| oneshot | 一次性的任务                                       |
| dbus    | 服务在 dbus 上注册成功以后，才算完成               |
| notify  | 启动后会发送一个通知信号的服务                     |

## 例子

```sh
/usr/local/lib/systemd/system/demo.service
```

```ini
[Unit]
Description=demo

[Service]
#User=root
#Group=root
Type=simple
#Environment="HOME=root"
WorkingDirectory=/opt/demo/_build/prod/rel/demo/bin/
ExecStart=/opt/demo/_build/prod/rel/demo/bin/demo start
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

设置开机自启

```sh
systemctl enable demo --now
```

查看状态：

```sh
systemctl status demo
journalctl -u demo
```
