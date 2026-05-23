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

```sh
System configuration  --->
  # 创建文件镜像之前，一般用来动态创建一些节点之类的
  (board/demo_vendor/demo_board/custom_fs/extra.sh)  Custom scripts to run before creating filesystem images
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
