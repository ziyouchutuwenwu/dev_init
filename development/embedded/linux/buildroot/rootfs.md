# rootfs

## 说明

`output/target` 目录最好手动备份

如果不小心删除，可以尝试

```sh
make busybox-reinstall
```

## 配置

```sh
make menuconfig
```

设置为 overlay_fs

```sh
System configuration  --->
  ($(BR2_EXTERNAL_AAA_PATH)/overlay_fs)  Root filesystem overlay directories
```

编译

```sh
# $OUTPUT_DIR/target 能看到
# 生成 etx2
make rootfs-ext2
```
