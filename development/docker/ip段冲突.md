# ip 段冲突

有时候，默认的虚拟 ip 段会和公司的冲突

## 删除虚拟网卡

查看 ip 段

```sh
docker network list
docker network rm xxxx
```

删除网卡

```sh
brctl show
ip link delete br-9692e3bf1fd1
```

## 修改配置

```sh
sudo vim /etc/docker/daemon.json
```

## 配置文件参考

设置 docker0 使用 192.168.10.1/16 网段

后面服务再创建地址池使用 10.50.0.0/16 网段范围划分，每个子网掩码划分为 255.255.255.0。

```json
{
  "bip": "192.168.10.1/24",
  "default-address-pools": [{ "base": "10.50.0.0/16", "size": 24 }],
  "registry-mirrors": [
    "https://vdi6uc6p.mirror.aliyuncs.com",
    "https://kfwkfulq.mirror.aliyuncs.com",
    "https://2lqq34jg.mirror.aliyuncs.com",
    "https://pee6w651.mirror.aliyuncs.com",
    "http://hub-mirror.c.163.com"
  ],
  "dns": ["8.8.8.8", "8.8.4.4"],
  "insecure-registries": [],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "debug": true
}
```

如果设置了 bip 失败，journalctl -xe | more 看，很可能是网关被占用，修改 bip 的 ip 即可

## 补充

创建虚拟网络

如果不设置 bip，则需要手动指定 subnet

```sh
docker network create --driver=bridge --subnet 192.168.xx.0/23 my_network
```
