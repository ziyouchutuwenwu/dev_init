# nuitka

打包为单独 exe 的工具

## 步骤

win7 需要安装 `KB2533623` 补丁，不然会报错 `ctype xxx`

### 安装

```sh
pacman -S --noconfirm mingw-w64-x86_64-python-nuitka mingw-w64-x86_64-ccache
```

### 编译

不编译所有的 imports

```sh
nuitka3 --standalone --remove-output --nofollow-imports --output-dir=build main.py
```

把引用的 aaa 和 bbb 两个目录一起编译到 exe 里面

```sh
nuitka3 --standalone --remove-output --follow-import-to=aaa,bbb --output-dir=build main.py
```

打包为单独 exe, 包含 result 目录

```sh
nuitka3 --standalone --remove-output --follow-import-to=result --output-dir=build main.py
```
