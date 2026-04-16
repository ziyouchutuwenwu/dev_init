# msys2

## 说明

建议用 mingw64 的 shell, 编译出来的依赖库最少

## 配置

### 换源

```sh
sed -i "s#mirror.msys2.org/#mirrors.ustc.edu.cn/msys2/#g" /etc/pacman.d/mirrorlist*
```

### 工具

```sh
pacman -Syyu --noconfirm
pacman -S --noconfirm base-devel vim curl axel git
```

mingw

```sh
pacman -S mingw-w64-x86_64-python-uv
pacman -S mingw-w64-x86_64-fd
pacman -S mingw-w64-x86_64-ripgrep
```

### profile

一般这三个，具体写法参考 os 的配置

```sh
proxy.sh
ls.sh
python.sh
```
