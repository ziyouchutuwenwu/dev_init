-module(demo_behavior_impl).

-behaviour(demo_behavior).
-compile(export_all).

on_demo_behavior_callback(Arg)->
  io:format("arg ~p~n",[Arg]),
  ok.

do()->
  Mod = ?MODULE,
  Mod:on_demo_behavior_callback(123).