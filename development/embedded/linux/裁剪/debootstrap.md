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
sudo pacman -S qemu-user-static debootstrap qemu-user-static-binfmt
```

### 下载

在 deb_fs 目录下创建

```sh
# 用 https 的源
sudo debootstrap --arch armhf --foreign --no-check-gpg bookworm deb_fs https://mirrors.ustc.edu.cn/debian
```

### 基础配置

```sh
sudo cp /usr/bin/qemu-arm-static ./deb_fs/usr/bin/

# sudo chroot ./deb_fs
sudo systemd-nspawn -D ./deb_fs
/debootstrap/debootstrap --second-stage
```

/etc/profile.d/sys_env.sh

```sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

~/.bashrc

```sh
[[ -f /etc/profile ]] && source /etc/profile
```

### 安装必备工具

```sh
source /etc/profile
apt install -y iputils-ping net-tools neovim
```

## 测试

### 制作镜像

```sh
# dd if=/dev/zero of=rootfs.ext4 bs=1M count=512
dd if=/dev/zero of=rootfs.ext4 bs=1G count=1
sudo mkfs.ext4 rootfs.ext4

mkdir mnt_fs
sudo mount -o loop rootfs.ext4 mnt_fs

sudo cp -rf ./deb_fs/* ./mnt_fs/

sudo umount mnt_fs
rm -rf mnt_fs
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
  -sd ~/downloads/rootfs.ext4
```
