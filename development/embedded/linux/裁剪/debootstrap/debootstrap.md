# debootstrap

## 说明

用来生成 rootfs

## 步骤

### 准备工作

debian

```sh
sudo apt install qemu-user-static debootstrap binfmt-support
```

manjaro

```sh
sudo pacman -S qemu-user-static debootstrap qemu-user-static-binfmt
```

### 创建虚拟机

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

```sh
apt install -y neovim
```

### profile

/etc/profile.d/path.sh

```sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

/etc/profile.d/ls.sh

```sh
alias ll='ls -la --color=auto' 2>/dev/null
alias l.='ls --color=auto -d .*' 2>/dev/null
alias ls='ls --color=auto' 2>/dev/null
```

/etc/profile.d/proxy.sh

```sh
alias pon="export HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118 ALL_PROXY=socks5://127.0.0.1:1080 NO_PROXY=localhost,127.0.0.1,10.0.2.1"
alias poff="unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY"
```

/etc/profile.d/python.sh

```sh
export PYTHONPYCACHEPREFIX=/dev/null
export UV_INDEX="https://mirrors.aliyun.com/pypi/simple"
```

~/.bashrc

```sh
[[ -f /etc/profile ]] && source /etc/profile
```

### 必备工具

```sh
source /etc/profile
apt install -y iputils-ping net-tools ncat file
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
