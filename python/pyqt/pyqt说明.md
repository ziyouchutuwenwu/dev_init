# pyqt 说明

## 注意点

- idea 里面, 建议创建自定义工具，用于 ui 文件编译为 py 脚本

- 命令行需要全路径, 比如

```bash
~/.pyenv/shims/python3
```

- 参数

```bash
-m PyQt5.uic.pyuic $FileName$ -o $FileNameWithoutExtension$.py
```

- 工作目录

```bash
$FileDir$
```
