# buildroot

## 准备

```sh
https://buildroot.org/downloads/buildroot-2025.02.3.tar.gz
```

## 配置

### defconfig

```sh
make O=output qemu_arm_vexpress_defconfig
```

### menuconfig

```sh
make O=output menuconfig
```

```sh
Bootloaders  --->
  [*] U-Boot
  (vexpress_ca9x4) Board defconfig
  U-Boot binary format  --->
    [*] u-boot
```

### 编译

```sh
make O=output -j$(nproc)
```

编译结果在 `output/images` 下
