# single

## 说明

single 模式，就是只启动到最小可用状态，只给一个 root 用户用，用于修系统。

## 步骤

```sh
启动的时候，在 grub 菜单上，按 e
在内核启动行，类似 kernel /vmlinuz-2.6.15 ro root=/dev/hda2，按 e
句末加 init=/bin/bash，看说明启动系统
```

得到一个 shell，默认是只读，我们要将其改为可写

```sh
mount -no remount,rw /
xxxx
sync
mount -no remount,ro /
reboot
```
