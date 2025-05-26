# debootstrap

## 说明

```sh
–foreign：在与主机架构不相同时需要指定此参数，仅做初始化的解包
```

## 步骤

### 安装工具

debian

```sh
sudo apt install qemu-user-static debootstrap binfmt-support
```

### 下载

```sh
sudo debootstrap --arch armel --foreign --no-check-gpg bookworm deb http://mirrors.ustc.edu.cn/debian
```

### 基础配置

```sh
sudo cp /usr/bin/qemu-arm-static deb/usr/bin/
sudo chroot deb
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
apt install iputils-ping net-tools vim -y
```

## 测试

### 制作镜像

```sh
dd if=/dev/zero of=deb_ifs.img bs=1M count=512
sudo mkfs.ext2 deb_ifs.img
mkdir deb_ifs
sudo mount -o loop deb_ifs.img deb_ifs
sudo cp -rf deb/* deb_ifs/
sudo umount deb_ifs
rm -rf deb_ifs
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
  -sd ~/downloads/deb_ifs.img
```
