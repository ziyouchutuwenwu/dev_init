# busybox

## 说明

编译成功以后，貌似需要做很多其它的工作

## 步骤

### 源码

```sh
https://busybox.net/downloads/busybox-1.36.1.tar.bz2
```

### menuconfig

```sh
mkdir output

make defconfig
make menuconfig
```

配置静态编译

```sh
# 不然会提示找不到 working dir
Settings  --->
  [*] Build static binary (no shared libs)
```

### 编译

```sh
make -j$(nproc) CONFIG_PREFIX=$(pwd)/../rootfs/ install
```

### 自定义脚本

用于打包 rootfs 目录

### 测试

append 后面的 root 不能缺

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/output/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/output/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/rootfs.ext4
```
