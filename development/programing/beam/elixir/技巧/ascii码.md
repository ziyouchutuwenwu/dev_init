# ascii 码

## 例子

```elixir
aa = ~c"d"
bb = aa |> List.to_string

# 获取 ascii 码
bb |> String.to_charlist |> List.first
```
