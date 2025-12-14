# tmux

## 用法

### 创建

```sh
tmux new -s xxx
```

### 附加

```sh
tmux a -t xxx
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

### 剪贴板

用支持 OSC52 协议的终端模拟器

如果不支持 OSC52

```sh
ssh -YC xx.xx.xx.xx
```

## 调试

按 prefix 键，然后和 vim 一样

```sh
:show-options -g
```

```sh
tmux show-options -g | rg pane
```
