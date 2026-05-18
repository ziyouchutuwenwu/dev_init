# nerves

## 说明

[支持的硬件](https://hexdocs.pm/nerves/supported-targets.html)

推荐 target 为 bbb 或 grisp2

## 用法

### 安装

```sh
mix archive.install hex nerves_bootstrap
```

### 创建

```sh
mix nerves.new nerves_demo
```

### 准备

设置 target

```sh
export MIX_TARGET=x86_64
```

### 依赖

```sh
mix deps.get
```

### 编译

需要[这个](https://github.com/fwup-home/fwup)

```sh
mix firmware
```

### 测试

```sh
qemu-img create -f raw disk.img 1G
fwup -d disk.img _build/x86_64_dev/nerves/images/nerves_demo.fw

qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -drive file=disk.img,if=virtio,format=raw \
  -netdev bridge,id=net0,br=virbr0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -serial mon:stdio
```

修改完以后测试

```sh
# qemu 里面，先看 ip
mix upload 10.0.2.238 --port 22
```

### 烧录

不支持虚拟机

```sh
mix burn
```
