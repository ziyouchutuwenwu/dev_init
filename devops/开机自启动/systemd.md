# systemd

## 说明

type 很重要，详情如下

| type    | 说明                           |
| ------- | ------------------------------ |
| simple  | 阻塞的服务，不会被推到后台     |
| forking | 推到后台的服务，不能阻塞       |
| idle    | 系统空闲时启动的服务           |
| oneshot | 启动后立刻退出的服务           |
| dbus    | 通过d-bus启动的服务            |
| notify  | 启动后会发送一个通知信号的服务 |

## 例子

```sh
/etc/systemd/system/demo.service
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
