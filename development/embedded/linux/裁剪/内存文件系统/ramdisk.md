# ramdisk

## 说明

内存中模拟磁盘。它将一部分内存空间作为磁盘来使用，可以像普通磁盘一样进行读写操作。

用于提高某些频繁访问的数据的读写速度，因为内存的访问速度远远快于物理磁盘。

## 步骤

### 制作

大小 4M

```sh
dd if=/dev/zero of=ramdisk.img bs=1M count=4
sudo mkfs.ext2 ramdisk.img
mkdir ramdisk
sudo mount -o loop ramdisk.img ramdisk
sudo cp -rf rootfs/* ramdisk/
sudo umount ramdisk
rm -rf ramdisk

gzip -9 -f ramdisk.img
```

### 内核配置

预定义参数

```sh
export CROSS_COMPILE=arm-linux-gnueabi-
export ARCH=arm
```

menuconfig

```sh
make O=./out_vexpress menuconfig
```

参数

```sh
General setup  --->
  [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
  [*] Support initial ramdisk/ramfs compressed using gzip
```

注意大小

```sh
Device Drivers  --->
  [*] Block devices  --->
    <*> RAM block device support
      (16)   Default number of RAM disks
      (4096) Default RAM disk size (kbytes)
```

```sh
File systems  --->
  <*> Second extended fs support
```

## 测试

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -initrd ~/downloads/buildroot-2023.02.2/output/images/ramdisk.img.gz \
  -append "root=/dev/ram0 rw console=ttyAMA0"
```
