# epmd

## 说明

类似 dns 服务, 同一个集群上的所有节点必须使用相同的 epmd 端口号

只要查询 4369 端口的情况，就可以知道集群的情况

在同一机器可能会部署不同的 erlang 集群，希望不要互相干扰。

## 用法

### 基本用法

```sh
epmd -daemon
epmd -daemon -port 5000
```

### 查询节点

查询 epmd 下所有的节点

```sh
epmd -names
epmd -port 5001 -names
```

### 单独启动模式

```erlang
epmd -daemon -port 5001
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

### 指定 ip

设置在指定 ip 上监听，不允许的节点 ip ，在 epmd 上也会注册，但是无法 connect

127.0.0.1 比较特殊，不受此限制

```sh
epmd -address 192.168.0.233,10.0.2.1 -debug
export ERL_EPMD_ADDRESS=192.168.0.233,10.0.2.1; epmd -debug

erl -name aaa@10.0.2.1 -setcookie 111 -epmd_address 10.0.2.1
erl -name bbb@10.0.2.1 -setcookie 111 -epmd_address 10.0.2.1

erl -name aaaa@192.168.56.1 -setcookie 111 -epmd_address 192.168.56.1
erl -name bbbb@192.168.56.1 -setcookie 111 -epmd_address 192.168.56.1
```

测试

```erlang
net_kernel:connect_node('aaa@10.0.2.1').
net_kernel:connect_node('aaaa@192.168.56.1').
```

### 设置端口范围

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
