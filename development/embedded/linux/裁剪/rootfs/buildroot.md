# buildroot

## 说明

这里用来编译 rootfs

## 步骤

### 源码下载

```sh
https://buildroot.org/downloads/buildroot-2025.02.3.tar.gz
```

### 默认配置

默认配置

```sh
make O=output defconfig
```

### menuconfig

```sh
make O=output menuconfig
```

````sh
# target 往外部的 toolchain 上凑
Target options  --->
  Target Architecture
     (ARM (big endian))
  Target Architecture Variant
     (cortex-A9)
  [*] Enable NEON SIMD extension support
  [*] Enable VFP extension support
  Target ABI (EABI)
  Floating point strategy
     (NEON)
  ARM instruction set
     (ARM)
  Target Binary Format
     (ELF)

# toolchain 一定要用自带的，不要用外部的，否则编译会失败，target 和外部的保持一致即可
```sh
Toolchain type --->
  (Buildroot toolchain)
  GCC compiler Version --->
    (gcc 12.x)

# tty 名字必须和 qemu 的 append 里面的 console 参数一致
System configuration
  /dev management--->
    (X) Dynamic using devtmpfs + mdev
  [*] Run a getty (login prompt) after boot  --->
    (ttyAMA0) TTY port

# 开启 ext2 的支持，大小设置 64M, 默认的 60M 会无法加载
Filesystem images  --->
  [*] ext2/3/4 root filesystem
    ext2/3/4 variant (ext2 (rev1))
    (rootfs) filesystem label (NEW)
    (64M) exact size
````

### 清理

```sh
make O=output mrproper
```

### 编译

编译的时候，它会自己下载很多源码，可以使用代理访问

```sh
make O=output -j$(nproc)
```

## 测试

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/output/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/output/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/buildroot-2025.02.3/output/images/rootfs.ext2
```
