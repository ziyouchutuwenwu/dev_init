# escript

## 说明

可执行脚本，运行需要机器预装 erlang

## 例子

```sh
rebar3 new escript demo
```

rebar.config

```erlang
% 启动需要的 app, 要在这个里面注册
% lib 类型的依赖，也要
% lib 的 .src 文件的 application 字段
{escript_incl_apps, [demo, gen_timer]}.
```

打包

```sh
rebar3 escriptize
```
