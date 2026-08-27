# tmux

## 说明

[这里](https://github.com/tmux/tmux-builds) 有 musl 版本

## 基本用法

### 创建

```sh
tmux new -s xxx
```

### 附加

```sh
tmux attach -t xxx
```

### 重命名

session 重命名

```sh
tmux rename -t old_xxx new_xxx
```

### 查看

```sh
tmux ls
```

### 杀掉

杀掉某个 session

```sh
tmux kill-session -t xxx
```

无论多少 session，都杀掉

```sh
tmux kill-server
```

## 其它用法

### 剪贴板

用支持 OSC52 协议的终端模拟器

如果不支持 OSC52

```sh
ssh -YC xx.xx.xx.xx
```

### 配置更新

热加载配置，文件可以自己指定

```sh
# source-file 的缩写
tmux source /etc/tmux.conf
```

### 缩写

查看所有缩写

```sh
tmux list-commands | grep -E '\(' | sed 's/ \[.*//'
```

### 调试

按 prefix 键，然后和 vim 一样

```sh
:show-options -g
```

```sh
tmux show-options -g | rg pane
tmux show-window-options -g | rg passthrough
```

### win 主机

如果是 win 主机，最好

```sh
set LANG=zh_CN.UTF-8
```
