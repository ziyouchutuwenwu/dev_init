# erlang 的调试配置

## 同步模块调试

- 用 idea 自带的项目创建模块
- 直接模块的方法上面下断点，然后 debug 即可

### 注意：

- 如果编译看不到 out 目录，尝试在 idea 的 setting 里面不选择 rebar 路径，编译选项里面只启用 debug_info
- 如果提示模块名错误，F4 打开项目选项，把 src 目录作为 source

## 异步调试，比较典型的为 opt 项目的断点调试

- [参考链接]([https://shayu.ltd:1688/articles/2019/10/22/1571726190169.html), 链接里面缺少修改`supervisor`

- 创建 rebar3 的项目 `rebar3 new app test_app`
- 创建一个这样的 erl，然后用上面一样的办法做模块级别的 debug，编译可以自己创建一个 rebar3 compile 的 task
- 创建一个这样的模块，用于断点调试

```erlang
-module(debug).

-export([debug/0]).

loop_sleep() ->
timer:sleep(5000),
loop_sleep().

%% 这里 application 的名字要根据请款改
debug() ->
application:start(test_app),
loop_sleep().

```
