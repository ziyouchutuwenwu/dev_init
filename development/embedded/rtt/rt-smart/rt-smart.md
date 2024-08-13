# rt-smart

## 说明

整理流程很像 linux, 先 load 内核，再加载 rootfs

## 步骤

### 配置 toolchain

下载

```sh
http://117.143.63.254:9012/www/rt-smart/aarch64-linux-musleabi_for_x86_64-pc-linux-gnu_latest.tar.bz2
```

```sh
export RTT_CC="gcc"
export RTT_EXEC_PATH="/opt/aarch64-linux-musleabi/bin/"
export RTT_CC_PREFIX="aarch64-linux-musleabi-"
export PATH="$RTT_EXEC_PATH:$PATH"
```

### 编译内核

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
source ~/.env/env.sh
pkgs --update

scons -c; scons
# scons --dist
```

### rootfs

#### 编译用户态程序

```sh
git clone --depth 1 https://github.com/RT-Thread/userapps.git
cd userapps; source env.sh
cd apps
```

先编译

```sh
xmake -j8
```

如果报错，则导出 toolchain

```sh
xmake smart-rootfs --export=all
```

重新 make

```sh
xmake -j8
```

#### 生成 rootfs

在 `apps/build/` 下会生成一个 rootfs 目录

```sh
xmake smart-rootfs
```

#### 生成磁盘镜像

```sh
xmake smart-image -o ../prebuilt/qemu-virt64-aarch64/ext4.img
```

#### 运行应用

```sh
/bin/hello
```
