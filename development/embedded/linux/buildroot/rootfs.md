# rootfs

## 说明

`output/target` 目录最好手动备份

如果不小心删除，可以尝试

```sh
make busybox-reinstall
```

## 方法

### 静态

```sh
make menuconfig
```

设置为 overlay_fs

```sh
System configuration  --->
  (board/demo_vendor/demo_board/overlay_fs)  Root filesystem overlay directories
```

目录结构如下

```sh
overlay_fs
└── usr
    └── local
        └── bin
            └── demo
```

编译

```sh
# output/target 能看到
# 生成 etx2
make rootfs-ext2
```

### 动态

```sh
make menuconfig
```

设置脚本，一般用来动态创建一些节点之类的

```sh
System configuration  --->
  (board/demo_vendor/demo_board/custom_fs/extra.sh)  Custom scripts to run before creating filesystem images
```

时期说明

```sh
# 在所有包开始编译之前执行。适合做一些环境准备，比如检查工具版本、下载外部文件。
()  Custom scripts to run before commencing the build

# 所有包编译完成、同步到 output/target/ 之后，在生成 .ext4、.cpio 等镜像文件之前执行。适合修 target 目录里的文件、删不需要的东西、创建设备节点。
() Custom scripts to run before creating filesystem images

# 在生成镜像文件时，Buildroot 会启动 fakeroot 模拟 root 权限。这个脚本在 fakeroot 环境内部运行，适合做需要 root 权限的操作（比如 mknod、chown、chmod）
()  Custom scripts to run inside the fakeroot environment

# 镜像文件（.ext4、zImage、dtb 等）已经全部生成到 output/images/ 之后执行。适合打包固件、生成校验和、上传到 TFTP 服务器等
(board/qemu/post-image.sh) Custom scripts to run after creating filesystem images
```

目录结构如下

```sh
custom_fs
├── files
│   └── demo
└── extra.sh
```

extra.sh

```sh
#!/bin/sh

# output/target
TARGET_DIR=$1
CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

mkdir -p ${TARGET_DIR}/usr/local/bin
cp -rf ${CURRENT_DIR}/files/* ${TARGET_DIR}/usr/local/bin/

chmod a+x ${TARGET_DIR}/usr/local/bin/*
```

编译

```sh
# output/target 能看到
# 生成 etx2
make rootfs-ext2
```
