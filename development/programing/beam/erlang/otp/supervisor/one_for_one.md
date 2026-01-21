# one_for_one

## 代码

### demo_sup.erl

```erlang
-module(demo_sup).

-behaviour(supervisor).

-export([start_link/2]).
-export([start_child/2]).
-export([init/1]).

start_link(Param1, Param2) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Param1, Param2]).

start_child(Param1, Param2) ->
  ChildSpec =
    % gen_server
      #{
        id => demo_server,
        start => {demo_server, start_link, [Param1, Param2]},
        % significant => true,
        restart => transient,
        shutdown => brutal_kill,
        type => worker,
        % gen_server 的话，这里需要填 dynamic
        modules => [dynamic]
      },

      % % 非 gen_server
      % #{
      %   id => demo_server,
      %   start => {demo_server, start_link, [Param1, Param2]},
      %   % significant => true,
      %   restart => permanent,
      %   shutdown => brutal_kill,
      %   type => worker,
      %   modules => [demo_server]
      % }
  supervisor:start_child(?MODULE, ChildSpec).

init([Param1, Param2]) ->
  MaxRestarts = 5,
  MaxSecondsBetweenRestarts = 10,

  SupervisorFlags =
    #{
      strategy => one_for_one,
      % auto_shutdown => any_significant,
      intensity => MaxRestarts,
      period => MaxSecondsBetweenRestarts
    },

  ChildSpecs =
    [
      % gen_server
      #{
        id => demo_server,
        start => {demo_server, start_link, [Param1, Param2]},
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
      %   start => {demo_server, start_link, [Param1, Param2]},
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

-export([start_link/2]).
-export([stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(my_record, {param1, param2}).

start_link(Param1, Param2) ->
  io:format("on start_link param1 ~p, param2 ~p~n", [Param1, Param2]),
  gen_server:start_link({local, ?MODULE}, ?MODULE, [Param1, Param2], []).

stop() ->
  gen_server:stop(?MODULE).

% -----------------------------------------------------------------------------
init([Param1, Param2]) ->
  io:format("on init param1 ~p, param2 ~p~n", [Param1, Param2]),
  {ok, #my_record{param1 = Param1, param2 = Param2}}.

handle_call(Msg, _From, State) ->
  {reply, {ok, Msg}, State};

handle_call(stop, _From, State) ->
  {stop, normal, State}.

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

-export([start_link/2]).
-export([init/2, loop/1]).

start_link(Param1, Param2) ->
  io:format("on start_link param1 ~p, param2 ~p~n", [Param1, Param2]),
  Pid = spawn_link(?MODULE, init, [Param1, Param2]),
  {ok, Pid}.

init(Param1, Param2)->
  register(?MODULE, self()),
  loop(Param1, Param2).

loop(Param1, Param2)->
  receive
    {crash} ->
      1/0;
    _Msg ->
      io:format("received msg ~p ~n", [Param1, Param2]),
      loop(Param1, Param2)
  end.
```

### demo.erl

```erlang
-module(demo).

-compile(export_all).

start_sup() ->
  demo_sup:start_link("param1", "param2").

check_sup() ->
  whereis(demo_sup).

check_child() ->
  whereis(demo_server).

check_children()->
  supervisor:which_children(demo_sup).

shutdown_child()->
  supervisor:terminate_child(demo_sup, demo_server),
  % demo_server:stop().
  % exit(whereis(demo_server), shutdown).
  supervisor:delete_child(demo_sup, demo_server),
  demo_sup:start_child("child1", "child2").

crash()->
  demo_server ! {crash}.
```
