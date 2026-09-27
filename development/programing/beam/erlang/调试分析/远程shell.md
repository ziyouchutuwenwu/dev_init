# 远程 shell

## 说明

远程操作节点

## 用法

### 手动

目标节点

```sh
erl -sname aaa -setcookie 111
```

本地节点

```sh
erl -sname xxx -setcookie 111
```

ctrl + g, 输入 h 查看可用的命令

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

### remsh

直接连接并操作远程节点

```sh
erl -sname bbb -setcookie 111 -remsh aaa@manjaro
```
