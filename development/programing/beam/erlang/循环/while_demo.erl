-module(while_demo).

-export([while/1,while/2, sum/0, sum_with_debug/0]).

while(List) -> while(List,0).
while([], Value) -> Value;
while([Element | Tail], Value) ->
  io:fwrite("~w~n",[Value]),
  while(Tail, Value + Element).

sum() ->
  List = [11,22,33,44],
  while(List).

%% 其中 ”{heap_size,22177879},” 表示堆区内存占用为 22177879 wordsize
%% 32位系统wordsize为4byte,64位系统wordsize为8byte, 可以通过erlang:system_info(wordsize).查看)
%% 在64位系统下169.2MB（22177879  * 8 / 1024 / 1024）, 太夸张了！
sum_with_debug()->
  sum(),
  {_, MemCost} = erlang:process_info(self(), heap_size),
  UnitBytes = erlang:system_info(wordsize),
  MemSize = MemCost * UnitBytes / 1024 / 1024,
  io:format("memcost ~p M~n", [MemSize]).