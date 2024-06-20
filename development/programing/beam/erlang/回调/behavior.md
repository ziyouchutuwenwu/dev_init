# behavior

类似面向对象的接口

## 代码

demo_behavior.erl

```erlang
-module(demo_behavior).

-callback say_hello(Name::string()) ->
  {noreply}.

-callback say_bye(Name::string()) ->
  {OK::atom()}.
```

demo_impl.erl

```erlang
-module(demo_impl).
-behaviour(demo_behavior).

-compile(export_all).

say_hello(Name) ->
  io:format("in demo_impl say_hello ~p~n",[Name]),
  {noreply}.

say_bye(Name) ->
  io:format("in demo_impl say_bye ~p~n",[Name]),
  ok.
```

test.erl

```erlang
-module(test).
-compile(export_all).

say_hello_demo(Mod)->
  Mod:say_hello("aaa").

say_bye_demo(Mod)->
  Mod:say_bye("bbb").
```

## 测试

```erlang
test:say_hello_demo(demo_impl).
test:say_bye_demo(demo_impl).
```
