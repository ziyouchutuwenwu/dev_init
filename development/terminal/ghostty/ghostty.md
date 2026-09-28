# ghostty

## 说明

从 [这里](https://github.com/pkgforge-dev/ghostty-appimage/) 找免编译版

## 配置

thunar 下配置右键

```sh
# 条件为目录
# 图标为 monitor
ghostty --working-directory=%f
```

在指定的终端 ghostty 内，用 nvim 打开文件

```sh
# .dektop 文件
Exec=ghostty -e nvim %F
Terminal=false
```
