# initramfs

## 说明

编译到内核里面，在系统启动的早期阶段被加载到内存中。

它通常包含了启动过程中所需的关键模块和工具，以便在真正的根文件系统可用之前，能够进行一些必要的初始化操作。

作用是为内核提供一个临时的工作环境，使内核能够加载必要的驱动程序、挂载真正的根文件系统等。

## 步骤

### rootfs

先编译好 rootfs

注意，根目录下，必须有 init 文件，可以复制 initrc 这个 link 为 init

### 编译内核

预定义参数

```sh
export CROSS_COMPILE=arm-linux-gnueabi-
export ARCH=arm
```

修改 linux 内核配置

```sh
make O=./out_vexpress menuconfig
```

```sh
General setup --->
  [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
  (/home/xxx/downloads/rootfs/) Initramfs source file(s)
```

```sh
make O=./out_vexpress -j12
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
