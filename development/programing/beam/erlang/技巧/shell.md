# shell

## 用法

### shell 相关

#### 查看消息

在当前 shell 内查看消息，调试用

```erlang
flush().
```

#### 历史记录

开启 shell 历史记录

```sh
export ERL_AFLAGS="-kernel shell_history enabled"
```

### record

#### module 内 record

把 Module 中的 Record 加载到 Shell 中

```erlang
rr(Module).
```

#### 子目录内 record

把在这个子目录下的所有 Module 里面的 Record 给加载到 Shell 里面

```erlang
rr("*/*").
```

### netstat

类似 netstat 的命令

```erlang
inet:i().
```
