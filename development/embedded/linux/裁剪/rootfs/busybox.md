# busybox

## 步骤

### 源码

```sh
https://busybox.net/downloads/busybox-1.36.1.tar.bz2
```

### menuconfig

预定义参数

```sh
export CROSS_COMPILE=arm-linux-gnueabi-
export ARCH=arm
```

```sh
make O=./out_vexpress menuconfig
```

配置静态编译

```sh
Settings  --->
  [*] Build static binary (no shared libs)
```

### 编译

```sh
make O=./out_vexpress -j12
make O=./out_vexpress CONFIG_PREFIX=./../rootfs/ install
```

### 生成 ext4 磁盘镜像

```sh
cd ../rootfs
mkdir  dev  etc  lib  usr  var  proc  tmp  home  root  mnt  sys
```

```sh
cp -rf ~/downloads/busybox-1.36.1/examples/bootfloppy/etc/* ./etc
```

修改 etc/profile

```sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
export LD_LIBRARY_PATH=/lib:/usr/lib
/bin/hostname my-os
USER=root
LOGNAME=$USER
HOSTNAME='/bin/hostname'
PS1='[\u@\h \W]# '
```

修改 etc/inittab

```sh
::sysinit:/etc/init.d/rcS
console::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
```

修改 etc/fstab

```sh
proc /proc proc defaults 0 0
none /var ramfs defaults 0 0
none /sys sysfs default  0 0
none /dev/pts devpts default  0 0
tmpfs /dev/shm tmpfs defaults 0 0
```

添加必要的节点

```sh
cd dev
sudo mknod -m 666 tty1 c 4 1
sudo mknod -m 666 tty2 c 4 2
sudo mknod -m 666 tty3 c 4 3
sudo mknod -m 666 tty4 c 4 4
sudo mknod -m 666 console c 5 1
sudo mknod -m 666 null c 1 3
```

看 rootfs 大小，4M 够了

```sh
dd if=/dev/zero of=rootfs.ext4 bs=1M count=4
sudo mkfs.ext4 rootfs.ext4
sudo mount -t ext4 rootfs.ext4 /mnt -o loop
sudo cp -rf rootfs/* /mnt/
sudo umount /mnt
```

### 测试

append 后面的 root 不能缺

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/rootfs.ext4
```
