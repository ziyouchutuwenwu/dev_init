# uboot 编译

## 步骤

### 准备工作

下载地址

```sh
https://ftp.denx.de/pub/u-boot/u-boot-2023.04.tar.bz2
```

### 编译

```sh
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- vexpress_ca9x4_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
```

### 测试

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/u-boot \
  -nographic
```
