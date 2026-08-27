# receive

## 说明

guard 跟在 when 后面

## 例子

```erlang
-module(demo).

-export([send_msg/0, receive_msg/0]).

send_msg() ->
    Self = self(),
    Self ! {msg, 10},
    Self ! {msg, -1},
    io:format("消息已发送~n").

receive_msg() ->
    receive
        {msg, N} when is_integer(N), N > 0 ->
            io:format("收到正消息: ~p~n", [N]);
        {msg, N} when is_integer(N) ->
            io:format("收到非正消息: ~p~n", [N])
    after 1000 ->
        io:format("接收超时~n")
    end.
```

测试

```erlang
demo:send_msg().
demo:receive_msg().
demo:receive_msg().
```
