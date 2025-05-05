# rt-smart

## 说明

整理流程很像 linux, 先 load 内核，再加载 rootfs

## 配置

以 qemu-virt64-aarch64 为例

### userapp

编译用户态程序

```sh
git clone --depth 1 https://github.com/RT-Thread/userapps.git
cd userapps; source env.sh
cd apps
```

先编译

```sh
# 配置为 aarch64平台，这个命令会下载一堆东西，包括toolchain
# 如果下载失败，手动下载，放在 userapps/downloaded/, 注意文件名需要按照提示里面的改掉
xmake config --arch=aarch64 -y
xmake -j8
```

导出 toolchain 和应用层开发的需要的 sdk，在 `apps/build/packages` 和 `apps/build/sdk` 下

```sh
xmake smart-rootfs --export=all
```

生成 rootfs，执行以后，在 `apps/build/` 下会生成一个 rootfs 目录

```sh
xmake smart-rootfs
```

生成磁盘镜像

```sh
xmake smart-image -f ext4
```

### 内核

toolchain 在 userapp 里面已经下载好了

```sh
export RTT_CC="gcc"
export RTT_EXEC_PATH="/opt/aarch64-linux-musleabi/bin/"
export RTT_CC_PREFIX="aarch64-linux-musleabi-"
export PATH="$RTT_EXEC_PATH:$PATH"
```

编译内核

```sh
git clone --depth 1 https://github.com/RT-Thread/rt-thread
cd bsp/qemu-virt64-aarch64
scons --menuconfig
```

```sh
RT-Thread Kernel --->
  [*] Enable RT-Thread Smart (microkernel on kernel/userland)

RT-Thread online packages  --->
  system packages  --->
    [*] lwext4: an excellent choice of ext2/3/4 filesystem for microcontrol
```

```sh
scons -c; scons
# scons --dist
```

### 运行

参考[这里](https://github.com/RT-Thread/userapps)最后生成 prebuilt 的部分里面的 run.sh
