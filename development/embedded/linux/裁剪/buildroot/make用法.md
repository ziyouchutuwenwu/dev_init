# make 用法

## 用法

```sh
# uboot
make O=output uboot-rebuild -j$(nproc)

# 内核
make O=output linux-rebuild -j$(nproc)

# 文件系统
make O=output busybox-rebuild -j$(nproc)
```

## 清理

```sh
# 清理特定包，不删除下载的源码
make O=output xxx-dirclean

# 保留下载的源码
make O=output clean

# 删除下载的源码
make O=output distclean
```
