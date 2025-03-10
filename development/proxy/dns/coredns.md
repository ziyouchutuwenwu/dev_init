# coredns

## 说明

按域名分流，会和 virt-manager 冲突，本地转发还是建议 mosdns

## 配置

### 例子

coredns.conf

```conf
# 默认，端口可以改
.:53 {
    forward . 223.5.5.5 223.6.6.6
    cache
    log
}

# 特定域名
example.com:53 {
    forward . 192.168.1.1
    cache
    log
}
```

### 运行

```sh
coredns -conf /usr/local/etc/coredns/coredns.conf
```

### systemd

/usr/local/lib/systemd/system/coredns.service

```ini
[Unit]
Description=coredns
After=network.target

[Service]
ExecStart=/usr/local/bin/coredns -conf /usr/local/etc/coredns/coredns.conf
Restart=on-failure
Environment=STDOUT=true
Environment=STDERR=true

[Install]
WantedBy=multi-user.target
```

设置开机自启

```sh
systemctl enable coredns --now
```

### 验证

```sh
dig @127.0.0.1 -p 53 google.com
nslookup -port=53 google.com 127.0.0.1
```
