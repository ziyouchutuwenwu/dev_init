# carp

## 说明

生成虚拟 ip, 类似 lvs 在 linux

## 配置

### 启用

临时加载

```sh
kldload carp
```

永久

/boot/loader.conf

```sh
carp_load="YES"
```

检查

```sh
kldstat | grep carp
sysctl net.inet.carp.allow
```

### 配置 ip

/etc/rc.conf

```sh
# 如果 xx 为现有网卡
ifconfig_xx="inet 10.0.2.33 netmask 255.255.255.0"

# vhid 为同一组的 id
# advskew 优先级，越小越高，如果相同，会随机选择 master
ifconfig_xx_alias0="inet vhid 1 advskew 100 pass 123456 alias 10.0.2.100/24"
```
