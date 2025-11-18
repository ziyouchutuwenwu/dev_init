# heart

## 说明

beam 被杀死以后，会重新启动，用于对于稳定性要求很高的场合。

## 例子

初始化

```sh
mix release.init
```

env.sh.eex, 取消以下注释

```sh
# 在 daemon 模式下会启动 heart
# 路径可以动态获取
case $RELEASE_COMMAND in
  daemon*)
    HEART_COMMAND="$RELEASE_ROOT/bin/$RELEASE_NAME $RELEASE_COMMAND"
    export HEART_COMMAND
    export ELIXIR_ERL_OPTIONS="-heart"
    ;;
  *)
    ;;
esac
```

编译

```sh
MIX_ENV=prod mix release
```

## 测试

### 查看变量

启动节点

```sh
bin/demo daemon
bin/demo remote
```

测试

```elixir
System.get_env("HEART_COMMAND")
System.get_env("HEART_BEAT_TIMEOUT")

:heart.get_cmd()
:heart.get_options()
```

### 杀掉

不可以用 pkill, 因为 heart 也是 erl 体系内的

```sh
ps aux | grep erl
kill -9 xxx
```

## 关闭

如果要关闭，则 remsh 到目标节点，执行

```elixir
:init.stop()
```
