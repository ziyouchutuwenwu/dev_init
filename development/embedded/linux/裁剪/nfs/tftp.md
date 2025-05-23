# tftp

## 说明

用来加载内核

## 步骤

### 准备工作

```sh
docker run --rm -d -it --name=tftpd -p 69:69/udp -v ~/projects/docker/tftp:/srv/tftp hkarhani/tftpd
```

### 编译内核

linux 内核需要编译为 uImage 格式，才能被 uboot 加载

```sh
make LOADADDR=0x60003000 uImage -j$(nproc)
```

### 启动测试

#### 启动 uboot

先参考 qemu 配置网络，进入 uboot 后中断

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/u-boot \
  -nographic \
  -net nic -net tap,ifname=tap0,script=no,downscript=no
```

#### 设置参数

207 是物理机 ip

```sh
setenv ipaddr 10.0.2.222
setenv serverip 10.0.2.207
ping 10.0.2.207
```

下载内核，设备树，启动

```sh
tftp 0x60003000 uImage
tftp 0x60500000 vexpress-v2p-ca9.dtb
bootm 0x60003000 - 0x60500000
```

### 重新编译 uboot

测试没问题以后，一次性修改 uboot 的启动参数

#### 修改配置

vexpress_common.h

```h
#define CONFIG_BOOTCOMMAND \
  "setenv ipaddr 10.0.2.222; \
    setenv serverip 10.0.2.207; \
    tftp 0x60003000 uImage; tftp 0x60500000 vexpress-v2p-ca9.dtb;  \
    setenv bootargs 'root=/dev/mmcblk0 rw init=/linuxrc ip=10.0.2.222 console=ttyAMA0';  \
    bootm 0x60003000 - 0x60500000;"
```

#### 编译

```sh
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
```

#### 运行

先参考 qemu 配置网络

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/u-boot \
  -nographic \
  -net nic -net tap,ifname=tap0,script=no,downscript=no
```

#### uboot 调试

查看变量

```sh
print xxx
```

手动执行

```sh
run bootcmd
```
