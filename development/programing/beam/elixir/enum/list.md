# List

## 用法例子

### flatten

```elixir
[[1, 2], [3, 4], [5, 6]] |> List.flatten
```

### delete

```elixir
List.delete([111, 2222, 3333], 2222)
List.delete_at([111, 2222, 3333], 1)
List.pop_at([111, 2222, 3333], 1)
```

### replace

```elixir
List.replace_at([111, 2222, 3333], 1, 7777777)
```

### update

```elixir
List.update_at([111, 2222, 3333], 1, fn(item) ->
  item + 20
end)
```

### 合并计算

- 返回单个结果
- 只有一个元素也能进入循环
- 类似 Enum.reduce
- 需设置 result 的初始值

```elixir
List.foldl(["aa", "bb", "cc"], "", fn item, saved_item ->
  saved_item <> item
end)
```

```elixir
List.foldl([1, 2, 3, 4], 0, fn item, result ->
  IO.inspect("each item #{item}, result #{result}")
  item + result
end)
```

参考 erlang 的

```erlang
lists:foldl(
  fun(Item, SavedItem) ->
    SavedItem ++ Item
  end,
  "",
  ["aa", "bb", "cc"]
).
```
