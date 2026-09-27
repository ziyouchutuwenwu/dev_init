# dr 模式的配置

## 说明

如果 lvs 和 rs 是分开的主机， **在 lvs 机上测试 vip, 是不通的**

## 模式对比

### nat 模式

- lvs 主机配置 vip 绑定

### dr 模式

- lvs 主机配置 vip 绑定
- lvs 主机配置 ip 转发
- rs 主机配置 arp 屏蔽
- rs 主机配置 vip 的绑定

## 步骤

### ip 转发配置

在 lvs 主机上配置

```sh
/etc/sysctl.d/ip_forward.conf
```

```sh
net.ipv4.ip_forward = 1
```

```sh
sysctl -p
```

### arp 配置

在 rs 配置, 如果 rs 和 lvs 在同一台机器，则不需要配置

```sh
/etc/sysctl.d/lvs_dr_rs.conf
```

```sh
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.lo.arp_ignore = 1

net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
```

```sh
sysctl -p
```

### 网络配置

在 rs 配置, 如果 rs 和 lvs 在同一台机器，则不需要配置

```sh
/etc/network/interfaces.d/dr_rs
```

```sh
auto lo:0
iface lo:0 inet static
  address $VIP
  netmask 255.255.255.255
  up ip route add $VIP/32 via $VIP dev lo:0
```

```sh
systemctl restart networking
```
