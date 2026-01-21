# heart

## 说明

beam 被杀死以后，会重新启动，用于对于稳定性要求很高的场合。

或者先 kill 掉 heart 进程，在 kill 掉 beam 进程

## 用法

### 测试

```erlang
os:getenv("HEART_COMMAND").
os:getenv("HEART_BEAT_TIMEOUT").

% 获取 HEART_COMMAND 命令
heart:get_cmd().
{ok,"erl -heart"}

% 设置临时 HEART_COMMAND 命令
heart:set_cmd("heart -shutdown").
ok

% 获取 HEART_COMMAND 命令，当临时 HEART_COMMAND 命令设置时取了 临时命令的值
heart:get_cmd().
{ok,"heart -shutdown"}

% 清除临时 HEART_COMMAND 命令
heart:clear_cmd().
ok

% 获取 HEART_COMMAND 命令
heart:get_cmd().
{ok,"erl -heart"}
```

### 关闭

remsh 到目标节点

```erlang
% heart stop
heart:stop().

% 应用 stop
init:stop().
```

或者 vm.args 注释掉 `-heart`， 重启应用

```sh
bin/demo stop
bin/demo daemon
```

不建议 kill

### 发布

erts 目录必须存在，prod 模式下默认存在

vm.args

```sh
# 启用 heart
-heart

# 设置 heart 检查间隔（秒），默认 30 秒
-env HEART_BEAT_TIMEOUT 10

# 不需要设置，
# _build/prod/rel/xxx/bin/xxx 脚本会自动设置这个环境变量
# -env HEART_COMMAND "/path/to/bin/demo daemon"

# 启动延迟（秒）
-env HEART_DELAY 5
```

打包

```sh
rebar3 as prod release
```
