# heart

beam 被杀死以后，会重新启动，用于对于稳定性要求很高的场合。

如果要关闭，则 remsh 到目标节点，执行

```elixir
:init.stop()
```

或者先 kill 掉 heart 进程，在 kill 掉 beam 进程

## 命令行

### 方法 1

节点 1

```sh
erl -heart -sname aaa@manjaro -setcookie 123456 -env HEART_COMMAND "erl -heart -sname aaa@manjaro -setcookie 123456" -env HEART_BEAT_TIMEOUT 10
```

节点 2

```erlang
erl -sname bbb@manjaro -setcookie 123456
net_kernel:connect_node('aaa@manjaro').
```

### 方法 2

节点 1

```sh
export HEART_COMMAND="erl -heart -sname aaa@manjaro -setcookie 123456"
export HEART_BEAT_TIMEOUT=10
erl -heart -sname aaa@manjaro -setcookie 123456
```

节点 2

```erlang
erl -sname bbb@manjaro -setcookie 123456
net_kernel:connect_node('aaa@manjaro').
```

切换到远程节点

```erlang
Ctrl + G
User switch command
 --> r 'aaa@manjaro'
 --> c
```

## 动态修改

```erlang
% 获取 HEART_COMMAND 命令
1> heart:get_cmd().
{ok,"erl -heart"}

% 设置临时 HEART_COMMAND 命令
2> heart:set_cmd("heart -shutdown").
ok

% 获取 HEART_COMMAND 命令，当临时 HEART_COMMAND 命令设置时取了 临时命令的值
3> heart:get_cmd().
{ok,"heart -shutdown"}

% 清除临时 HEART_COMMAND 命令
4> heart:clear_cmd().
ok

% 获取 HEART_COMMAND 命令
5> heart:get_cmd().
{ok,"erl -heart"}
```

关闭心跳

```erlang
q().
init:stop().
```

## rebar3 项目

### vm.args.src

这个文件支持环境变量

```sh
-setcookie 123456
-env HEART_COMMAND "/xxx/rel/demo_release/bin/demo_release daemon"
-env HEART_BEAT_TIMEOUT 10
-heart
```

### 启动

如果在 vm.args.src 里面没有设置 HEART_COMMAND 和 HEART_BEAT_TIMEOUT

则手动指定

```sh
export HEART_COMMAND="demo_release daemon"
export HEART_BEAT_TIMEOUT=10
```

启动

```sh
/rel/demo_release/bin/demo_release daemon
```

### 检查

```sh
erl -setcookie 123456 -sname bbb@manjaro
net_kernel:connect_node('prod_release@manjaro').
```

切换到远程节点

```erlang
Ctrl + G
User switch command
 --> r 'prod_release@manjaro'
 --> c
```

或者

```sh
erl -setcookie 123456 -sname bbb@debian -remsh prod_release@manjaro
```

查看已经启动的应用

```erlang
application:loaded_applications().
```

## 强行杀死

在某些时候，无法进入 shell, 可以参考下面的强行 kill

```sh
ps aux | grep erl
ps aux | grep beam
```
