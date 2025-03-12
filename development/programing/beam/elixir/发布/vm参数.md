# vm 参数

## 用法

生成模板

```sh
mix release.init
```

打包

```sh
mix release
```

## vm 参数

vm.args.eex

[参数说明](https://www.erlang.org/doc/man/erl.html)

默认已经启用多核支持

设置最大的 port 数

```sh
# :erlang.system_info(:port_limit)
+Q 65536
```

设置环境变量

```sh
# System.get_env("AAA")
-env AAA mmc
```

设置最大进程数

```sh
# :erlang.system_info(:process_limit)
+P 10000000
```

启用 epoll 支持

```sh
+K true
```

开启并行 port 并行调度队列，当开启后会大大增加系统吞吐量，如果关闭，则会牺牲吞吐量换取更低的延迟。

```sh
+spp true
```

分布式 erlang 的端口 buffer 大小，当 buffer 满的时候，向分布式的远程端口发送消息会阻塞

```sh
+zdbbl 65536
```

设置 ets 表的最大值

```sh
+e 1024
```
