-module(demo_behavior).

-callback on_demo_behavior_callback(Arg::any())->
  {OK::atom()}.