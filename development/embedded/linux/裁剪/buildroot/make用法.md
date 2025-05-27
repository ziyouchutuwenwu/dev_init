# make 用法

## 用法

```sh
# uboot
make O=output uboot-dirclean -j$(nproc)
make O=output uboot-rebuild -j$(nproc)

# 内核
make O=output linux-dirclean -j$(nproc)
make O=output linux-rebuild -j$(nproc)

# 文件系统
make O=output busybox-dirclean -j$(nproc)
make O=output busybox-rebuild -j$(nproc)
```
