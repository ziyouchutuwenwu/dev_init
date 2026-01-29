# buildroot

## 说明

目前自定义设备树测试会有问题，等新版

## 源码

```sh
https://buildroot.org/downloads/buildroot-2025.11.1.tar.gz
```

## 配置

### 独立配置

配置和设备树独立出来

```sh
mkdir -p board/demo_vendor/demo_board
```

### 设备树

linux 内核自带设备树的路径，build 以后才能看到

```sh
output/build/linux-*/arch/arm/boot/dts/
```

目录结构

```sh
board/demo_vendor
└── demo_board
    ├── demo_board.defconfig
    └── dts
        └── demo_board.dts
```

或者模拟三方厂商

```sh
board/demo_vendor
└── demo_board
    ├── demo_board.defconfig
    └── dts
        └── demo_vendor
            └── demo_board
                └── demo_board.dts
```

demo_board.dts

```dts
/dts-v1/;

#include "arm/vexpress-v2p-ca9"

/ {
    model = "Simple Demo Board";
    compatible = "demo_vendor,simple_demo_board";
};
```

### deconfig

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

# 启用设备树
Kernel  --->
  [*]   Build a Device Tree Blob (DTB)
  # 和厂商一样配置，更通用
  (board/demo_vendor/demo_board/dts) Out-of-tree Device Tree Source overlay directories

Target packages  --->
  # 这个要选中，不然 vim 和 bash 都看不到
  [*]   Show packages that are also provided by busybox
    Development tools  --->
    # gnu sed，自带的不标准，elixir 会报错
    [*] sed
    # sh 对标准的支持太差
    Shell and utilities  --->
      [*] bash
    Text editors and viewers  --->
      [*] vim
```

### 保存配置

保存配置

```sh
make O=output BR2_DEFCONFIG=board/demo_vendor/demo_board/demo_board.defconfig savedefconfig
```

还原配置

```sh
make O=output BR2_DEFCONFIG=board/demo_vendor/demo_board/demo_board.defconfig defconfig
```

### 编译

```sh
make O=output -j$(nproc)
```

编译结果在 `output/images` 下
