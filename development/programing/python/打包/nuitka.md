# nuitka

## 说明

nuitka 比 pyinstaller 体积更小

## 例子

### 安装

```sh
pip install nuitka
```

### 打包

把引用的 aaa 和 bbb 两个目录一起编译到 exe 里面

```sh
nuitka3 --onefile main.py --output-filename=xx --remove-output --follow-import-to=aaa,bbb --output-dir=build
```

pyside6 程序

```sh
nuitka3 --onefile main.py --output-filename=xx --remove-output --output-dir=build --enable-plugin=pyside6
```

某些代码使用 cython 编译为动态库以后，需要手动指定

```sh
nuitka3 --onefile main.py --output-filename=xx --remove-output --follow-import-to=aaa,bbb --output-dir=build
```

### win

加参数避免启动出现黑框, ico 可以用其它图片格式替换

```sh
--windows-disable-console --windows-icon-from-ico=res/icon/default.ico
```
