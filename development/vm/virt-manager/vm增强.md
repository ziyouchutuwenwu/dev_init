# vm 增强

## 说明

用于共享剪贴板，分辨率自适应

### 物理机

debian

```sh
sudo apt install qemu-guest-agent
```

manjaro

```sh
yay -S spice-guest-tools-windows
```

### 虚拟机

#### win

虚拟机挂载驱动, 对应在物理机上的路径

```sh
/usr/share/spice-guest-tools/spice-guest-tools.iso
```

vm 最好使用 qxl 作为显卡，不然缩放会出问题

#### debian

虚拟机安装

```sh
sudo apt install spice-vdagent
```

#### manjaro

虚拟机安装

```sh
sudo pacman -S spice-vdagent
```
