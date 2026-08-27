# make

## 用法

## 解压源码

```sh
# 没有下载的会下载
make uboot-extract

make linux-extract

make busybox-extract
```

### 子项配置

```sh
make uboot-menuconfig
make linux-menuconfig
make busybox-menuconfig
```

子项更新配置，用于配置拆分以后，把当前的配置，同步到拆分出来的配置文件里面

```sh
# 运行之前，一定要先 xxx-menuconfig
make uboot-update-defconfig
make linux-update-defconfig
make busybox-update-config
```

### rebuild

```sh
# uboot
make uboot-rebuild

# 内核
make linux-rebuild

# 文件系统
make busybox-rebuild
```

### 清理

单个包

只删除 $OUTPUT_DIR/build/xxx/

```sh
make xxx-dirclean
```

.config 和 下载的源码不删

```sh
make clean
```

全删，保留下载的源码

```sh
make clean && rm -f .config && rm -rf $OUTPUT_DIR

# 或者备份 dl 目录
make distclean
```

全删

配置保存到其它目录的，不删

```sh
make distclean
```
