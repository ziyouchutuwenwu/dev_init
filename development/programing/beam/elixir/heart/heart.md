# heart

## 说明

beam 被杀死以后，会重新启动，用于对于稳定性要求很高的场合。

## 用法

### 配置

初始化

```sh
mix release.init
```

不需要修改 vm.args.eex

env.sh.eex, 取消以下注释

```sh
# daemon 模式下启用
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

### 打包

```sh
MIX_ENV=prod mix release
```

设置变量位置如下，和 erlang 的位置不一样

```sh
_build/prod/rel/xxx/releases/0.1.0/env.sh
```

### 测试

启动

```sh
bin/demo daemon
bin/demo remote
```

查看

```elixir
System.get_env("HEART_COMMAND")
System.get_env("HEART_BEAT_TIMEOUT")

:heart.get_cmd()
:heart.get_options()
```

### 关闭

remsh 到目标节点

```elixir
# heart stop
:heart.stop

# 应用 stop
:init.stop
```
