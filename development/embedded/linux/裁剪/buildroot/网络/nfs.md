# nfs

## 配置

### 内核配置

启用 nfs

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

### 整体配置

启用 uImage, 设置加载地址

```sh
make O=output menuconfig
```

```sh
Kernel  --->
  [*] Linux Kernel
    Kernel binary format (uImage)
    (0x60003000) load address (for 3.7+ multi-platform image)
```

打包 rootfs

```sh
Filesystem images  --->
  [*] tar the root filesystem
```

uboot 配置

```sh
Bootloaders  --->
  (boot.env) Text file with default environment
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
  -kernel ~/downloads/u-boot-2023.04/output/u-boot \
  -nographic \
  -netdev bridge,id=net0,br=virbr0 \
  -net nic,netdev=net0
```

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel /home/mmc/downloads/buildroot-2025.02.3/output/images/u-boot \
  -nographic \
  -netdev bridge,id=net0,br=virbr0 \
  -net nic,netdev=net0 \
  -no-reboot
```

```sh
setenv ipaddr 10.0.2.222
setenv serverip 10.0.2.1
setenv bootargs 'root=/dev/nfs rw nfsvers=3 nfsroot=10.0.2.1:/mnt/nfs/rootfs init=/linuxrc console=ttyAMA0 ip=10.0.2.222'
setenv bootcmd 'tftp 0x60003000 uImage; tftp 0x60500000 vexpress-v2p-ca9.dtb; bootm 0x60003000 - 0x60500000'
saveenv

tftp 0x60003000 uImage
tftp 0x60500000 vexpress-v2p-ca9.dtb
bootm 0x60003000 - 0x60500000
```
