# initramfs

## 说明

这个是编译到内核里面去了

## 步骤

### rootfs

先编译好 rootfs

注意，根目录下，必须有 init 文件，可以复制 initrc 这个 link 为 init

### 编译内核

修改 linux 内核配置

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./out_vexpress menuconfig
```

```sh
General setup --->
  [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
  (/home/xxx/downloads/rootfs/) Initramfs source file(s)
```

```sh
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm O=./out_vexpress -j8
```

生成的文件系统压缩文件在这里

```sh
out_vexpress/usr/initramfs_data.cpio
```

## 测试

```sh
qemu-system-arm \
 -M vexpress-a9 \
 -m 512M \
 -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
 -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
 -nographic \
 -append "noinitrd console=ttyAMA0,115200 root=/dev/ram0 rw"
```

或者

```sh
qemu-system-arm \
 -M vexpress-a9 \
 -m 512M \
 -kernel ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/zImage \
 -dtb ~/downloads/linux-5.10.191/out_vexpress/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
 -nographic \
 -initrd ~/downloads/linux-5.10.191/out_vexpress/usr/initramfs_data.cpio
```
