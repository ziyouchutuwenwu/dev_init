# epmd

## 描述

类似 dns 服务, 同一个集群上的所有节点必须使用相同的 epmd 端口号

## 问题

只要查询 4369 端口的情况，就可以知道集群的情况

在同一机器可能会部署不同的 erlang 集群，希望不要互相干扰。

## 查询 epmd 下所有的节点

```sh
epmd -names
epmd -port 5001 -names
```

## 修改监听端口

### 单独启动模式

- 先启动 epmd

```sh
epmd -daemon -port 5000
```

```sh
kill -9 `pidof epmd`
```

- 再启动节点

指定 epmd 的端口

```erlang
erl -name bbb@127.0.0.1 -setcookie 111 -epmd_port 5001
```

如果要在 rebar3 的项目里面配置, 参考 `vm.args`

```sh
-epmd_port 5001
```

### 环境变量模式

```sh
export ERL_EPMD_PORT=5001; erl -name ccc@127.0.0.1 -setcookie 111
```

## 监听指定 ip

epmd 服务在指定 ip 上监听

### 使用启动参数

```sh
epmd -address 192.168.88.96,127.0.0.1 -daemon
```

### 使用环境变量

```sh
export ERL_EPMD_ADDRESS=192.168.88.96,127.0.0.1; epmd -daemon
```

### shell 内配置

貌似只支持单 ip

```sh
erl -name aaa@192.168.88.96 -setcookie 111 -kernel inet_dist_use_interface "{127,0,0,1}"
```

### 测试

```sh
epmd -address 127.0.0.1 -daemon
ps aux | grep epmd
kill -9 `pidof epmd`
```

```sh
erl -name aaa@192.168.88.96 -setcookie 111
erl -name bbb@192.168.88.96 -setcookie 111

erl -name aaaa@127.0.0.1 -setcookie 111
erl -name bbbb@127.0.0.1 -setcookie 111
```

```erlang
net_kernel:connect_node('aaa@192.168.88.96').
net_kernel:connect_node('aaaa@127.0.0.1').
```

## 设置端口范围

命令行配置

```sh
erl -sname aaa -kernel inet_dist_listen_min 4370 inet_dist_listen_max 4371
erl -sname bbb -kernel inet_dist_listen_min 4370 inet_dist_listen_max 4371
erl -sname ccc -kernel inet_dist_listen_min 4370 inet_dist_listen_max 4371
```

代码中配置

```erlang
application:set_env(kernel, inet_dist_listen_min, 9100).
application:set_env(kernel, inet_dist_listen_max, 9105).
```

配置文件内配置

```erlang
{ kernel, [
  {inet_dist_listen_min, 6000},
  {inet_dist_listen_max, 7999}
]}
```
