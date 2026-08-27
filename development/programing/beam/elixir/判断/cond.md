# cond

## 说明

支持多重条件

匹配条件可以用函数

## 用法

```elixir
info1 = ""
info2 = ""

cond do
  String.length(info1) !== 0 ->
    "info1 not 0"

  String.length(info2) !== 0 ->
    "info2 not 0"

  String.length(info1) === 0 && String.length(info2) === 0 ->
    "len are 0"

  true ->
    "default"
end
```
