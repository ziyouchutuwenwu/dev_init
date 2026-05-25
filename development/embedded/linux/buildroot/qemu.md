# qemu

## 说明

退出用 `ctrl-a, x`

## 用法

uboot

```sh
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 1G \
  -bios u-boot.bin \
  -nographic
```

kernel + rootfs

```sh
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 1G \
  -kernel Image \
  -drive file=rootfs.ext4,if=none,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -append "root=/dev/vda rootwait console=ttyAMA0"
```

kernel + rootfs + dtb

这里的 dtb 是整体替换 dtb，乱写的话，会无法启动

```sh
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 1G \
  -kernel Image \
  -drive file=rootfs.ext4,if=none,format=raw,id=hd0 \
  -dtb demo_board.dtb \
  -device virtio-blk-device,drive=hd0 \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -append "root=/dev/vda rootwait console=ttyAMA0"
```

uboot + kernel + rootfs

```sh
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 1G \
  -bios u-boot.bin \
  -kernel Image \
  -drive file=rootfs.ext4,if=none,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -append "root=/dev/vda rootwait console=ttyAMA0"
```

整个 img

虚拟机下测试，dtb 不会被加载

```sh
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 1G \
  -bios u-boot.bin \
  -drive file=disk.img,if=none,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic
```
