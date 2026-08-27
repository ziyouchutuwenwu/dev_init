# case

## 说明

本质上是模式匹配，do 后面的必须是 value

## 用法

```elixir
require Logger

case xxx("aaa") do
  "aaa" ->
    Logger.debug("aaa")

  "bbb" ->
    Logger.debug("bbb")
  _ ->
    Logger.debug("default")
end
```
