# epmd

## 说明

默认端口 4369

用于分离集群，一个集群用同一个端口

不太适合容器化

## 配置

### 命令行

```erlang
epmd -daemon -port 5001
erl -name bbb@127.0.0.1 -setcookie 111 -epmd_port 5001
```

### rebar3

vm.args

```erlang
-epmd_port 5001
```

### 环境变量

rebar3 项目和普通 shell 都支持

```sh
export ERL_EPMD_PORT=5001
erl -name ccc@127.0.0.1 -setcookie 111
```

### 调试

```sh
# 启动
epmd -daemon -port 5000

# 查询
epmd -port 5001 -names
```
