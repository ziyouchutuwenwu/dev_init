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
mix nerves.new demo
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
fwup -d disk.img _build/x86_64_dev/nerves/images/demo.fw

qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -drive file=disk.img,if=virtio,format=raw \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::10022-:22 \
  -nographic \
  -serial mon:stdio
```

修改完以后测试

```sh
mix upload 127.0.0.1 --port 10022
```

### 烧录

不支持虚拟机

```sh
MIX_TARGET=bbb mix firmware.burn
```
