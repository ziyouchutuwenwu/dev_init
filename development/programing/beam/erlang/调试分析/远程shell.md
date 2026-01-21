# 远程 shell

作为远程被操作节点

```sh
erl -sname aaa -setcookie 111 -detached
```

## JCL 作业模式

作为操作节点

```sh
erl -sname bbb -setcookie 111
```

### 进入作业模式

ctrl + g, 输入 h 查看可用的命令

连接远程节点

```sh
r aaa@manjaro
```

查看可用的 job

```sh
j
```

执行 job， 此时处于远程节点

```sh
c 2
```

终结远程节点，直接输入

```sh
q().
```

退出远程节点

```sh
ctrl + g, 输入 q
```

## remote shell 模式

```sh
erl -sname bbb -setcookie 111 -remsh aaa@manjaro
```
