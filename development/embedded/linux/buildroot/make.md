# make

## 用法

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

只删除 output/build/xxx/

```sh
make xxx-dirclean
```

.config 和 下载的源码不删

```sh
make clean
```

全删，保留下载的源码

```sh
make clean && rm -f .config && rm -rf output

# 或者备份 dl 目录
make distclean
```

全删

配置保存到其它目录的，不删

```sh
make distclean
```
