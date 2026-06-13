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
# 路径是自动获取的，不要改这里
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

# 升级的时候，手动设置这个变量，然后触发 beam 的重启
:heart.set_cmd(~c"/opt/demo/0.2.0/bin/demo daemon")
```

### 触发

```elixir
:erlang.halt
System.halt
```

### 关闭

remsh 到目标节点

```elixir
# 应用 stop
:init.stop
```
