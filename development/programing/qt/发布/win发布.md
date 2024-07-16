# win 发布

通过 msys2

## 步骤

### 安装工具链

```sh
pacman -S --noconfirm mingw-w64-x86_64-qt5-static
pacman -S --noconfirm make
```

### 设置环境变量

```sh
vim /etc/profile.d/profile.sh
```

```sh
export PATH=$MSYS2_ROOT/mingw64/qt5-static/bin:$PATH
```

### 静态编译

```sh
cd /z
qmake xxx.pro
make
```
