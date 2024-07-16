# heart

## 说明

beam 被杀死以后，会重新启动，用于对于稳定性要求很高的场合。

如果要关闭，则 remsh 到目标节点，执行

```elixir
:init.stop()
```

## 步骤

### 生成 release

#### 初始化模板

```sh
MIX_ENV=prod mix release.init
```

#### 修改配置

rel/env.sh.eex

```sh
# daemon 模式下启用 heart 机制
case $RELEASE_COMMAND in
  daemon*)
    HEART_COMMAND="$RELEASE_ROOT/bin/$RELEASE_NAME $RELEASE_COMMAND"
    export HEART_COMMAND
    export ELIXIR_ERL_OPTIONS="-heart"
    ;;
  *)
    ;;
esac

# 指定 name 和 cookie
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=aaa@127.0.0.1
export RELEASE_COOKIE=123456
```

#### 生成

```sh
MIX_ENV=prod mix release
```

### 测试

#### 启动节点

节点 1

```sh
bin/demo daemon
```

节点 2

```elixir
iex --name bbb@127.0.0.1 --cookie 123456

Node.connect(:'aaa@127.0.0.1')
:net_kernel.connect_node(:'aaa@127.0.0.1')
```

#### 杀掉

杀掉 beam 的进程以后，会重启

```sh
ps aux | grep beam
kill -9 xxx
```
