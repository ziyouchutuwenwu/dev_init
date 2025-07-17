# gen_statem

## 用法

[参考地址](https://blog.csdn.net/Dylan_2018/article/details/110149169)

推荐 `handle_event_function` 模式

### event_function 模式

```erlang
-module(pushbutton).

-behaviour(gen_statem).

-export([start/0, push/0, get_count/0, stop/0]).
-export([terminate/3, code_change/4, init/1, callback_mode/0]).
-export([handle_event/4]).

callback_mode() ->
  handle_event_function.

start() ->
  gen_statem:start({local, aaa}, ?MODULE, [], []).

init([]) ->
  State = off,
  Count = 0,
  {ok, State, Count}.

code_change(_Vsn, State, Data, _Extra) ->
  {ok, State, Data}.

terminate(Reason, State, Data) ->
  io:format("on terminate ~p ~p ~p~n", [Reason, State, Data]),
  void.

push() ->
  gen_statem:cast(aaa, push).

get_count() ->
  gen_statem:call(aaa, get_count).

stop() ->
  gen_statem:stop(aaa).


% 回调函数
% 参数为:
%   {call, From}, 动作，状态，数据
%   cast, 动作，状态，数据
handle_event(cast, push, off, Count) ->
  {next_state, on, Count + 1};

handle_event(cast, push, on, Count) ->
  {next_state, off, Count};

handle_event({call, From}, get_count, State, Count) ->
  {next_state, State, Count, [{reply, From, Count}]};

handle_event(Method, _From, State, Data) ->
  io:format("其它消息 ~p ~p~n", [Method, State]),
  {next_state, State, Data}.
```

### state_functions 模式

```erlang
-module(pushbutton).

-behaviour(gen_statem).

-export([start/0, push/0, get_count/0, stop/0]).
-export([terminate/3, code_change/4, init/1, callback_mode/0]).
-export([on/3, off/3]).

callback_mode() ->
  state_functions.

start() ->
  gen_statem:start({local, aaa}, ?MODULE, [], []).

init([]) ->
  State = off,
  Data = 0,
  {ok, State, Data}.

code_change(_Vsn, State, Data, _Extra) ->
  {ok, State, Data}.

terminate(Reason, State, Data) ->
  io:format("on terminate ~p ~p ~p~n", [Reason, State, Data]),
  void.

push() ->
  gen_statem:call(aaa, push).

get_count() ->
  gen_statem:call(aaa, get_count).

stop() ->
  gen_statem:stop(aaa).

% 回调函数
% 函数名为 oldState
% 参数为:
%   {call, From}, 状态，数据
%   cast, 状态，数据
off({call, From}, push, Count) ->
  {next_state, on, Count + 1, [{reply, From, on}]};

off(EventType, EventContent, Count) ->
  io:format("off 方法其它消息 ~p ~p~n", [EventType, EventContent]),
  handle_event(EventType, EventContent, Count).

on({call, From}, push, Count) ->
  {next_state, off, Count, [{reply, From, off}]};

on(EventType, EventContent, Data) ->
  io:format("on 方法其它消息 ~p ~p~n", [EventType, EventContent]),
  handle_event(EventType, EventContent, Data).

%% 这里是在 on 或者 off 回调里面主动触发
handle_event({call, From}, get_count, Data) ->
  {keep_state, Data, [{reply, From, Data}]};

handle_event(_, _, Data) ->
  {keep_state, Data}.
```

## 测试

```erlang
pushbutton:start().
pushbutton:push().
pushbutton:push().
pushbutton:get_count().
pushbutton:stop().
```
