-module(debug).

%% 参数是app的名字
-export([debug/1]).

loop_sleep() ->
  timer:sleep(5000),
  loop_sleep().

debug(AppName) ->
  application:start(AppName),
  loop_sleep().