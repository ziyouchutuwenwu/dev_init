# uboot

## 步骤

### 准备

下载地址

```sh
https://ftp.denx.de/pub/u-boot/u-boot-2026.04.tar.bz2
```

### 编译

```sh
make qemu_arm64_defconfig
make
```

### 测试

qemu 加载 uboot 需要用 elf 的格式

bin 格式的没有入口点，适合烧录到板子上

```sh
qemu-system-arm64 \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/output/u-boot \
  -nographic
```

### 调试

查看变量

```sh
printenv xxx
```

手动执行，比如你定义了 bootcmd

```sh
run bootcmd
```

重启

```sh
reset
```
