# gen_event

用于动态绑定 handler

## 例子

terminal_logger.erl

```erlang
-module(terminal_logger).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, terminate/2]).

init(_Args) ->
  {ok, []}.

handle_call(Request, State) ->
  {ok, Request, State}.

handle_event(ErrorMsg, State) ->
  io:format("std log ~p~n", [ErrorMsg]),
  {ok, State}.

terminate(_Args, _State) ->
  ok.
```

file_logger.erl

```erlang
-module(file_logger).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, terminate/2]).

init(File) ->
  {ok, Fd} = file:open(File, [read, write]),
  {ok, Fd}.

handle_call(Request, State) ->
  {ok, Request, State}.

handle_event(ErrorMsg, Fd) ->
  io:format(Fd, "file log ~p~n", [ErrorMsg]),
  {ok, Fd}.

terminate(_Args, Fd) ->
  file:close(Fd).
```

## 测试方法

```erlang
% init 函数在 add_handler 的时候被具体模块处理，所以在 start 的时候，不需要指定 init 方法
gen_event:start({local, demo_err_log}).

gen_event:add_handler(demo_err_log, terminal_logger, []).
gen_event:notify(demo_err_log, 11111).

gen_event:add_handler(demo_err_log, file_logger, ["file_logger.txt"]).
gen_event:notify(demo_err_log, 22222).

gen_event:delete_handler(demo_err_log, file_logger, ["file_logger.txt"]).
gen_event:notify(demo_err_log, 33333).
```
