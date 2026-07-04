# debootstrap

## 说明

buildroot 里面，一般都是裁剪过的，这个可以用来补充动态库

## 步骤

### 准备

voidlinux

```sh
sudo xbps-install qemu-user-static debootstrap binfmt-support
```

debian

```sh
sudo apt install qemu-user-static debootstrap binfmt-support
```

manjaro

```sh
sudo pacman -S qemu-user-static debootstrap qemu-user-static-binfmt
```

### 配置

```sh
sudo debootstrap --arch armhf --foreign --no-check-gpg trixie deb_fs https://mirrors.ustc.edu.cn/debian
```

```sh
# voidlinux 下需要
sudo update-binfmts --import qemu-arm
sudo update-binfmts --enable qemu-arm
```

```sh
sudo cp /usr/bin/qemu-arm ./deb_fs/usr/bin/

# sudo systemd-nspawn -D ./deb_fs
sudo chroot ./deb_fs /usr/bin/bash
```

然后

```sh
/debootstrap/debootstrap --second-stage
```
