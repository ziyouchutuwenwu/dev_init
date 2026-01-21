# case

## 说明

guard 跟在 when 后面

## 例子

```erlang
-module(demo).

-export([demo/1]).

demo(X) ->
    case X of
        N when is_integer(N), N > 0 ->
            io:format("正整数: ~p~n", [N]);
        N when is_integer(N) ->
            io:format("非正整数: ~p~n", [N]);
        _ ->
            io:format("不是整数~n")
    end.
```

测试

```erlang
demo:demo(10).
demo:demo(-5).
demo:demo("abc").
```
