# if

## 说明

guard 跟在 when 后面

## 例子

```erlang
-module(demo).
-export([demo/1]).

demo(X) ->
    if
        is_integer(X), X > 0 ->
            io:format("if: 正整数 ~p~n", [X]);
        is_integer(X) ->
            io:format("if: 非正整数 ~p~n", [X]);
        true ->
            io:format("if: 不是整数~n")
    end.
```

测试

```erlang
demo:demo(10).
demo:demo(-5).
demo:demo("abc").
```
