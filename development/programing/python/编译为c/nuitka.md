# nuitka

主要用于打包为整个 exe

## 用法

### 安装

```sh
pip install nuitka
```

### 选项

- --standalone 生成很多的 so 库，很多不太需要，可以手工删除

- --onefile 生成单独的 exe

- --nofollow-imports 一些依赖包例如动态库可能已经不需要编译了, 不适用于 standalone 模式

### 运行

```sh
nuitka3 --standalone --remove-output --output-dir=build main.py
```

把引用的 aaa 和 bbb 两个目录一起编译到 exe 里面

```sh
nuitka3 --onefile --remove-output --follow-import-to=aaa,bbb --output-dir=build main.py
```

打包为单独 exe, 包含 result 目录

```sh
nuitka3 --onefile --remove-output --follow-import-to=result --output-dir=build main.py
```
