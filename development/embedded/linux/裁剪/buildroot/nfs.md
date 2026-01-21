# nfs

## 准备工作

配置好网络, tftp, nfs 等服务

## 配置

### 内核

启用 nfs，默认已经开启了

```sh
make O=output linux-menuconfig
```

```sh
File systems  --->
  [*] Network File Systems  --->
    <*> NFS client support
    <*> NFS client support for NFS version 3
    [*] Root file system on NFS
```

### uboot

核心已经支持, 就算不选中, nfs 也可以加载

```sh
make O=output uboot-menuconfig
```

```sh
Command line interface  --->
  [*] nfs
```

### 整体

启用 uImage, 设置加载地址

```sh
make O=output menuconfig
```

```sh
Kernel  --->
  [*] Linux Kernel
    Kernel binary format (uImage)
    (0x60010000) load address (for 3.7+ multi-platform image)
```

打包 rootfs

```sh
Filesystem images  --->
  [*] tar the root filesystem
```

uboot 配置环境变量

```sh
Bootloaders  --->
  (uboot.env) Text file with default environment
```

uboot.env

内存地址一定要注意，否则可能会无法启动

```sh
ipaddr=10.0.2.222
# ttfp 服务器 ip
serverip=10.0.2.1
# 最后的 ip 不能缺
root=/dev/nfs rw nfsroot=10.0.2.1:/mnt/nfs/rootfs,nfsvers=3 init=/linuxrc console=ttyAMA0 ip=10.0.2.222
# bootm 中间的 - 不能缺
bootcmd=tftp 0x60010000 uImage; tftp 0x61000000 vexpress-v2p-ca9.dtb; bootm 0x60010000 - 0x61000000
```

### 编译

```sh
make O=output -j$(nproc)
```

### 测试

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/buildroot-2025.02.3/output/images/u-boot \
  -nographic \
  -netdev bridge,id=net0,br=virbr0 \
  -net nic,netdev=net0
```

手动，支持变量展开，需要用双引号，单引号不支持

```sh
setenv ipaddr 10.0.2.222
setenv serverip 10.0.2.1
setenv bootargs "root=/dev/nfs rw nfsroot=${serverip}:/mnt/nfs/rootfs,nfsvers=3 init=/linuxrc console=ttyAMA0 ip=${ipaddr}"
setenv bootcmd 'tftp 0x60010000 uImage; tftp 0x61000000 vexpress-v2p-ca9.dtb; bootm 0x60010000 - 0x61000000'
saveenv

run bootcmd
```
