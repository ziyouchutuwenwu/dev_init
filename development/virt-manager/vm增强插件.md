# vm 增强插件

用于共享剪贴板，分辨率自适应

## 说明

物理机需要安装 `qemu-guest-agent`
vm 需要安装 `spice-vdagent`

### win

物理机安装

```sh
yay -S spice-guest-tools-windows
```

挂载路径为

```sh
/usr/share/spice-guest-tools/spice-guest-tools.iso
```

vm 最好使用 qxl 作为显卡，不然缩放会出问题

### debian

虚拟机安装

```sh
sudo apt install spice-vdagent
```

### manjaro

虚拟机安装

```sh
sudo pacman -S spice-vdagent
```
