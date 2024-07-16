# appimage 打包

linux 下打包为一个独立绿色可执行程序

最好在低版本 glibc 的系统下打包

## 例子

### 准备工作

#### 普通程序

普通程序用 linuxdeploy

```sh
https://github.com/linuxdeploy/linuxdeploy
```

#### qt 程序

qt 程序用 linuxdeployqt

```sh
https://github.com/probonopd/linuxdeployqt
```

#### appimagetool

打包为绿色可执行文件的工具

```sh
https://github.com/AppImage/AppImageKit
```

#### patchelf

```sh
sudo pacman -S patchelf
```

### 步骤

#### 普通程序打包

准备好可执行文件和 icon，icon 名字必须和工程名字一致

```sh
linuxdeploy --appdir=../no_qt_pack -e ./demo -i demo.svg --create-desktop-file
```

#### qt 程序打包

找到需要打包的文件

```sh
release
└── demo
```

执行

```sh
linuxdeployqt ./release/demo -appimage -unsupported-allow-new-glibc
```

```sh
sed -i '1 a Categories=Utility;' release/default.desktop
```

#### 打包为绿色文件

```sh
appimagetool ./release xxx_bin
```
