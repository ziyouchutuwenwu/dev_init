# debootstrap

## 说明

用来生成 rootfs

## 步骤

### 安装工具

debian

```sh
sudo apt install qemu-user-static debootstrap binfmt-support
```

manjaro

```sh
sudo apt install qemu-user-static debootstrap qemu-user-static-binfmt
```

### 下载

在 deb_fs 目录下创建

```sh
# 用 https 的源
sudo debootstrap --arch armel --foreign --no-check-gpg bookworm deb_fs https://mirrors.ustc.edu.cn/debian
```

### 基础配置

```sh
sudo cp /usr/bin/qemu-arm-static ./deb_fs/usr/bin/
sudo chroot deb_fs
/debootstrap/debootstrap --second-stage
```

```sh
vi /etc/profile.d/sys_env.sh
```

```sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### 安装必备工具

```sh
source /etc/profile
apt install -y iputils-ping net-tools neovim
```

## 测试

### 制作镜像

```sh
dd if=/dev/zero of=deb_rootfs.img bs=1M count=512
sudo mkfs.ext2 deb_rootfs.img
mkdir deb_rootfs
sudo mount -o loop deb_rootfs.img deb_rootfs
sudo cp -rf deb_fs/* deb_rootfs/
sudo umount deb_rootfs
rm -rf deb_rootfs
```

### qemu

```sh
qemu-system-arm \
  -M vexpress-a9 \
  -m 512M \
  -kernel ~/downloads/linux-5.10.191/output/arch/arm/boot/zImage \
  -dtb ~/downloads/linux-5.10.191/output/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
  -nographic \
  -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
  -sd ~/downloads/deb_rootfs.img
```
