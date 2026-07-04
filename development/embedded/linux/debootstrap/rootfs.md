# rootfs

## 说明

用来做 rootfs

## 步骤

制作镜像

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

qemu

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
