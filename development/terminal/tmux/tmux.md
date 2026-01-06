# tmux

## 基本用法

### 创建

```sh
tmux new -s xxx
```

### 附加

```sh
tmux a -t xxx
```

### 重命名

```sh
tmux rename-session -t old_xxx new_xxx
```

### 查看

```sh
tmux ls
```

### kill

```sh
tmux kill-session -t xxx
```

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
tmux source-file /etc/tmux.conf
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
