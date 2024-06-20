# asdf 用法

## 环境

```sh
git clone --depth 1 https://github.com/asdf-vm/asdf.git ~/.asdf
```

```sh
source $HOME/.asdf/asdf.sh
```

## 用法

### 查询 plugin

查询已经安装的 plugin

```sh
asdf plugin list
```

查询所有 plugin

```sh
asdf plugin list-all
```

### 安装 plugin

安装 nodejs 的 plugin

```sh
asdf plugin add nodejs
asdf plugin remove nodejs
```

### 查看版本

查看 nodejs 安装好的版本

```sh
asdf list nodejs
```

查看 nodejs 的大版本号为 20 的所有版本

```sh
asdf list-all nodejs 20
```

### 安装

```sh
asdf install nodejs 20.12.0
asdf uninstall nodejs 20.12.0
```

### 设置默认

全局

```sh
asdf global nodejs 20.12.0
```

当前目录

```sh
asdf local nodejs 20.12.0
```

版本定义的文件所在路径

```sh
~/.tool-versions
```
