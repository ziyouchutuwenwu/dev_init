# buildroot

## 步骤

### 源码

```sh
https://buildroot.org/downloads/buildroot-2022.11.tar.xz
```

### 默认配置

生成默认配置

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./output defconfig
```

### menuconfig

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./output menuconfig
```

配置 target

```sh
Target options  --->
   Target Architecture (ARM (big endian))
   Target Architecture Variant (cortex-A9)
   Target ABI (EABI)
   Floating point strategy (NEON/VFPv4)
   ARM instruction set (ARM)
   Target Binary Format (ELF)
```

libc 和内核版本

```sh
Toolchain  --->
  C library (musl)
  Kernel Headers (Linux 5.10.x kernel headers)
```

设置系统信息，比如 banner, 密码等等

tty 名字必须和 qemu 的 append 里面的 console 参数一致

```sh
System configuration
  /dev management--->
    (X) Dynamic using devtmpfs + mdev
  [*] Run a getty (login prompt) after boot  --->
    (ttyAMA0) TTY port
```

开启 ext2 的支持，大小设置 64M, 默认的 60M 会无法加载

```sh
Filesystem images  --->
  [*] ext2/3/4 root filesystem
    ext2/3/4 variant (ext2 (rev1))
    (rootfs) filesystem label (NEW)
    (64M) exact size
```

### 清理

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./output mrproper
```

### 编译

编译的时候，它会自己下载很多源码，可以使用 proxychains 代理访问

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./output -j8
```

## 测试

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/buildroot-2023.02.2/output/images/rootfs.ext2
```
