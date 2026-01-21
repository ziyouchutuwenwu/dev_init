# simple_one_for_one

## 代码

### demo_sup.erl

```erlang
-module(demo_sup).

-behaviour(supervisor).

-export([start_link/2]).
-export([start_child/2]).
-export([init/1]).

start_link(InitParam1, InitParam2) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [InitParam1, InitParam2]).

start_child(ChildParam1, ChildParam2) ->
  supervisor:start_child(?MODULE, [ChildParam1, ChildParam2]).

init([InitParam1, InitParam2]) ->
  % 在 MaxSeconds 内，所有子进程加起来的最大的重启次数超过 MaxRestarts，所有子进程都会以 shutdown 的原因被杀掉
  % 并且 supervisor 也会被杀掉
  MaxRestarts = 5,
  MaxSeconds = 10,

  SupervisorFlags =
    #{
      strategy => simple_one_for_one,
      % auto_shutdown => any_significant,
      intensity => MaxRestarts,
      period => MaxSeconds
    },

  ChildSpecs =
    [
      % gen_server
      #{
        id => demo_server,
        start => {demo_server, start_link, [InitParam1, InitParam2]},
        % significant => true,
        restart => transient,
        shutdown => brutal_kill,
        type => worker,
        % gen_server 的话，这里需要填 dynamic
        modules => [dynamic]
      }

      % % 非 gen_server
      % #{
      %   id => demo_server,
      %   start => {demo_server, start_link, [InitParam1, InitParam2]},
      %   % significant => true,
      %   restart => permanent,
      %   shutdown => brutal_kill,
      %   type => worker,
      %   modules => [demo_server]
      % }
    ],

  {ok, {SupervisorFlags, ChildSpecs}}.
```

### demo_server.erl

```erlang
-module(demo_server).
-behaviour(gen_server).

-export([start_link/4]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(my_record, {param1, param2}).

start_link(InitParam1, InitParam2, ChildParam1, ChildParam2) ->
  io:format("on start_link init_param1 ~p, init_param2 ~p, child_param1 ~p, child_param2 ~p~n", [InitParam1, InitParam2, ChildParam1, ChildParam2]),
  gen_server:start_link(?MODULE, [ChildParam1, ChildParam2], []).

init([Param1, Param2]) ->
  io:format("on init param1 ~p, param2 ~p~n", [Param1, Param2]),
  register(Param1, self()),
  {ok, #my_record{param1 = Param1, param2 = Param2}}.

handle_call(Msg, _From, State) ->
  {reply, {ok, Msg}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Msg, #my_record{param1 = Param1, param2 = Param2} = State) ->
  io:format("demo handle_info ~p ~p~n", [Param1, Param2]),
  {noreply, State}.

terminate(Reason, StateData) ->
  io:format("demo process terminated~p ~p ~p~n", [self(), Reason, StateData]),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
```

### 或者

```erlang
-module(demo_server).

-export([start_link/4]).
-export([init/2, loop/1]).

start_link(InitParam1, InitParam2, Name, ChildParam) ->
  io:format("init_param1 ~p, init_param2 ~p, child_param1 ~p, child_param2 ~p~n", [InitParam1, InitParam2, Name, ChildParam]),
  Pid = spawn_link(?MODULE, init, [Name, ChildParam]),
  {ok, Pid}.

init(Name, ChildParam)->
  register(Name, self()),
  loop(ChildParam).

loop(ChildParam)->
  receive
    {crash} ->
      1/0;
    _Msg ->
      io:format("received msg ~p ~n", [ChildParam]),
      loop(ChildParam)
  end.
```

### demo.erl

```erlang
-module(demo).

-compile(export_all).

start_sup() ->
  % demo_sup:start_link(child1, "child1_p").
  demo_sup:start_link("p1", "p2").

start_child1()->
  demo_sup:start_child(child1, "child1_p").

start_child2()->
  demo_sup:start_child(child2, "child2_p").

check_sup() ->
  whereis(demo_sup).

check_child1() ->
  whereis(child1).

check_child2() ->
  whereis(child2).

check_children()->
  supervisor:which_children(demo_sup).

shutdown_child1()->
  supervisor:terminate_child(demo_sup, whereis(child1)).

shutdown_child2()->
  exit(whereis(child2), shutdown).
  % exit(whereis(child2), aaa).

crash()->
  child1 ! {crash}.
```
