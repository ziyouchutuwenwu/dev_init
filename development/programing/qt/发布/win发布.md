# win 发布

## 说明

通过 msys2 编译

## 步骤

### 工具链

```sh
pacman -S --noconfirm mingw-w64-x86_64-qt5-static
pacman -S --noconfirm make
```

### 环境变量

/etc/profile.d/qt.sh

```sh
export PATH=$MSYS2_ROOT/mingw64/qt5-static/bin:$PATH
```

### 静态编译

```sh
cd /z
qmake xxx.pro
make
```
