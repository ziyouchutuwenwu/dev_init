# tftp

## 说明

用来加载内核

## 步骤

### 准备工作

```sh
# tftp 10.0.2.1
# get xxx
docker run --rm -d -it --name=tftpd --net=host -v ~/projects/docker/tftp:/srv/tftp hkarhani/tftpd
```

### 编译内核

内核需要 uImage 格式，才能被 uboot 加载

```sh
make LOADADDR=0x60003000 uImage -j$(nproc)
```

把 `output/arch/arm/boot/uImage` 和 `dts` 放到 `tftp` 的目录

### uboot

#### 启动

进入 uboot 后中断

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/output/u-boot \
  -nographic \
  -netdev bridge,id=net0,br=virbr0 \
  -net nic,netdev=net0
```

#### 设置参数

```sh
# qemu 虚拟机 ip
setenv ipaddr 10.0.2.222

# tftp 服务器 ip
setenv serverip 10.0.2.1
ping 10.0.2.1
```

下载内核，设备树，启动

```sh
tftp 0x60003000 uImage
tftp 0x60500000 vexpress-v2p-ca9.dtb
bootm 0x60003000 - 0x60500000
```

#### 定义宏

vexpress_common.h

```h
#ifdef CONFIG_BOOTCOMMAND
#undef CONFIG_BOOTCOMMAND
#endif
#define CONFIG_BOOTCOMMAND \
  "setenv ipaddr 10.0.2.222; \
    setenv serverip 10.0.2.1; \
    tftp 0x60003000 uImage; tftp 0x60500000 vexpress-v2p-ca9.dtb;  \
    setenv bootargs 'root=/dev/mmcblk0 rw init=/linuxrc ip=10.0.2.222 console=ttyAMA0';  \
    bootm 0x60003000 - 0x60500000;"
```

#### 编译

```sh
make -j$(nproc)
```

#### 运行

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/output/u-boot \
  -nographic \
  -netdev bridge,id=net0,br=virbr0 \
  -net nic,netdev=net0
```

#### 调试

查看变量

```sh
print xxx
```

手动执行

```sh
run bootcmd
```
