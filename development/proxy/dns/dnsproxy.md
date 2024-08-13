# dnsproxy

## 说明

<https://github.com/AdguardTeam/dnsproxy>

## 步骤

### 设置本地 dns 服务器

```sh
/etc/systemd/system/dnsproxy.service
```

```ini
[Unit]
Description=dnsproxy

[Service]
Type=simple
# xxx.com 域名的解析使用 xxx.xxx.xxx.xxx
ExecStart=dnsproxy -l 127.0.0.1 -u [/xxx.com/]xxx.xxx.xxx.xxx -u 223.5.5.5 -u 223.6.6.6
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

设置开机自启

```sh
systemctl enable dnsproxy --now
```

### 验证

```sh
dig @127.0.0.1 -p 53 google.com
nslookup -port=53 google.com 127.0.0.1
```
