# asdf 用法

## 安装

```sh
git clone --depth 1 https://github.com/asdf-vm/asdf.git ~/.asdf
```

vim ~/.profile

```sh
source $HOME/.asdf/asdf.sh
```

```sh
asdf update
```

## 检查插件

### 查询支持的插件

```sh
asdf plugin list all
```

### 增加某语言支持

```sh
asdf plugin add python
asdf plugin remove python
```

## 查看某语言版本

```sh
asdf list elixir
asdf list all elixir
```

### 安装某语言的某个版本

如果你没有加版本号，则默认安装的是该语言的所有可用版本

```sh
asdf install python 3.9.14
asdf uninstall python 3.9.14
```

## 设置默认

```sh
asdf global python 3.9.14
asdf local python 3.7.14
```

版本定义的文件所在路径

```sh
~/.tool-versions
```
