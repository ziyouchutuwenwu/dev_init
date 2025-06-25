# gen_server

## 代码

demo_server.erl

```erlang
-module(demo_server).
-behaviour(gen_server).

-export([start_link/2]).
-export([stop/0, async_stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(my_record, {param1, param2}).

start_link(Param1, Param2) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [Param1, Param2], []).

stop() ->
  gen_server:stop(?MODULE).

async_stop() ->
  gen_server:cast(?MODULE, stop).

% ---------------------------------------------------------------------
init([Param1, Param2]) ->
  {ok, #my_record{param1 = Param1, param2 = Param2}}.

handle_call(Msg, _From, State) ->
  {reply, {ok, Msg}, State};

handle_call(stop, _From, State) ->
  {stop, normal, "demo_server stopped", State}.

handle_cast(_Msg, State) ->
  io:format("demo_server handle_cast ~p ~n", [_Msg]),
  {noreply, State};

handle_cast(stop, State) ->
  {stop, normal, State}.

handle_info(_Msg, #my_record{param1 = Param1, param2 = Param2} = State) ->
  io:format("demo_server handle_info ~p ~p~n", [Param1, Param2]),
  {noreply, State}.

terminate(Reason, StateData) ->
  io:format("demo_server terminated~p ~p ~p~n", [self(), Reason, StateData]),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
```

## init 之后自动执行代码

[文档地址](https://erlang.org/doc/man/gen_server.html#Module:init-1)

### timout 大法

```erlang
-record(my_state_record, {param}).

init([]) ->
  Timout = 0,
  {ok, #my_state_record{param = "aabc"}, Timout}.

handle_info(timeout,  #my_state_record{param = Param} = State) ->
  io:format("handle_info timeout ~p ~p~n", [self(), Param]),
  {noreply, State};

handle_info(_Info, StateData) ->
  {noreply, StateData}.
```

### continue 大法

```erlang
-record(my_state_record, {param}).

init([]) ->
  {ok, #my_state_record{param = "aabc"}, {continue, run_after_init}}.

handle_continue(run_after_init,  #my_state_record{param = Param} = State) ->
  io:format("handle_continue ~p~n", [Param]),
  {noreply, State}.
```
