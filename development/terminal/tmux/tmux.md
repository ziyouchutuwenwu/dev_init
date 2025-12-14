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

## 调试

按 prefix 键，然后和 vim 一样

```sh
:show-options -g
```

```sh
tmux show-options -g | rg pane
```
