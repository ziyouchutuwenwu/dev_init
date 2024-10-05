# qemu

## 说明

想要实现 qemu 虚拟机和外部通信，只能使用 tap/bridge 模式

## 步骤

### 安装工具

```sh
sudo apt install uml-utilities bridge-utils
```

### 配置网卡

qemu-ifup

```sh
#! /bin/bash

QEMU_NET_BRIDGE=$1
REAL_NIC_NAME=$2

if [ $# != 2 ] ; then
  echo "usage: $0 qemu_br0 enp1s0"
  exit 1;
fi

if [ "$(id -u)" -ne 0 ] ; then
    echo "need run as root" $0
    exit 1;
fi

ifconfig $REAL_NIC_NAME down
brctl addbr $QEMU_NET_BRIDGE
brctl addif $QEMU_NET_BRIDGE $REAL_NIC_NAME
brctl stp $QEMU_NET_BRIDGE on
brctl sethello $QEMU_NET_BRIDGE 1
ifconfig $QEMU_NET_BRIDGE 0.0.0.0 promisc up
ifconfig $REAL_NIC_NAME 0.0.0.0 promisc up
dhclient $QEMU_NET_BRIDGE
brctl show $QEMU_NET_BRIDGE
brctl showstp $QEMU_NET_BRIDGE

tunctl -u $(id -un) -t tap0
ifconfig tap0 0.0.0.0 promisc up
brctl addif $QEMU_NET_BRIDGE tap0
brctl show
```

qemu-ifdown

```sh
#! /bin/bash

QEMU_NET_BRIDGE=$1

if [ $# != 1 ] ; then
  echo "usage: $0 qemu_br0"
  exit 1;
fi

if [ "$(id -u)" -ne 0 ] ; then
    echo "need run as root" $0
    exit 1;
fi

ifconfig tap0 down
ifconfig $QEMU_NET_BRIDGE down
tunctl -d tap0
brctl delif $QEMU_NET_BRIDGE tap0
brctl delbr $QEMU_NET_BRIDGE
brctl show
```

```sh
sudo chmod +x qemu*
```

## 测试

### 网络配置

配置桥接网络

```sh
sudo qemu-ifup qemu_br0 enp1s0
sudo qemu-ifdown qemu_br0
```

### 运行

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/buildroot-2023.02.2/output/images/rootfs.ext2 \
  -net nic -net tap,ifname=tap0,script=no,downscript=no
```

### 设置 ip

qemu 跑起来的 vm 里面的网卡，需要和宿主机的 qemu_br0 同一个网段

```sh
vi /etc/init.d/rcS
```

```sh
ifconfig eth0 10.0.2.222 netmask 255.255.255.0
```
