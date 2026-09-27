-module(for_demo).

-export([for/2,demo/0, demo_with_debug/0]).

for(0,_) ->
  [];
for(LoopIndex, FinalIndex) when LoopIndex > 0 ->
  io:fwrite("Hello ~p~n", [LoopIndex]),
  % 下面两种都可以
  for(LoopIndex -1, FinalIndex).
  % [FinalIndex | for(LoopIndex -1, FinalIndex)].

demo() ->
  for(5,1).

demo_with_debug()->
  demo(),
  {_, MemCost} = erlang:process_info(self(), heap_size),
  UnitBytes = erlang:system_info(wordsize),
  MemSize = MemCost * UnitBytes / 1024 / 1024,
  io:format("memcost ~p M~n", [MemSize]).