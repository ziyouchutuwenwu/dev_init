# vm 参数

## 说明

release 模式下

位置 config/vm.args

## 配置

```sh
-name aaa@127.0.0.1
-sname aaa
-setcookie mycookie
```

```sh
# 高 io 负载时启用，减少系统调用
+K true
```

```sh
# 最大进程数
+P 10485760
```

```sh
# 异步 io
+A 10
```

```sh
# 最大原子数
+t 2097152
```

```sh
# gc
-env ERL_FULLSWEEP_AFTER 10
```

```sh
# 端口
-env ERL_MAX_PORTS 4096
```
