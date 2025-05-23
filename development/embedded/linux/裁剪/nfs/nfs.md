# nfs

## 说明

用于加载文件系统

## 步骤

### 准备工作

文件系统复制到 nfs 下面

注意，这里用的 nfs 的版本是 3,可以通过以下命令看到

```sh
docker logs -f nfs-server
```

```sh
# mount -t nfs -o nolock 10.0.2.207:/mnt/nfs ./nfs
docker run --rm -d --name nfs-server -v ~/projects/docker/nfs/:/mnt/nfs -e NFS_EXPORT_DIR_1=/mnt/nfs -e NFS_EXPORT_DOMAIN_1=\* -e NFS_EXPORT_OPTIONS_1=rw,insecure,no_subtree_check,no_root_squash,fsid=1 -p 111:111 -p 111:111/udp -p 2049:2049 -p 2049:2049/udp -p 32765:32765 -p 32765:32765/udp -p 32766:32766 -p 32766:32766/udp -p 32767:32767 -p 32767:32767/udp --privileged=true fuzzle/docker-nfs-server:latest
```

### linux 内核

#### 重新配置

```sh
make menuconfig
```

```sh
File systems  --->
  [*] Network File Systems  --->
    <*> NFS client support
    <*> NFS client support for NFS version 3
    [*] Root file system on NFS
```

#### 编译

使用 uImage, 支持 uboot 从网络加载

编译结束后，uImage 复制到 tftp 根目录

```sh
make LOADADDR=0x60003000 uImage -j$(nproc)
```

### uboot 修改

#### 修改配置

vexpress_common.h

注意 nfs 的版本号

```h
#define CONFIG_BOOTCOMMAND \
  "setenv ipaddr 10.0.2.222; \
    setenv serverip 10.0.2.207; \
    tftp 0x60003000 uImage; tftp 0x60500000 vexpress-v2p-ca9.dtb;  \
    setenv bootargs 'root=/dev/nfs rw nfsvers=4 nfsroot=10.0.2.207:/mnt/nfs/rootfs,nfsvers=3 init=/linuxrc console=ttyAMA0 ip=10.0.2.222';  \
    bootm 0x60003000 - 0x60500000;"
```

#### 重新编译

```sh
make -j$(nproc)
```

### 测试

```sh
sudo qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/u-boot-2023.04/u-boot \
  -nographic \
  -net nic -net tap,ifname=tap0,script=no,downscript=no
```
