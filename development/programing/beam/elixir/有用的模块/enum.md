# Enum

## 用法

### 是否在列表内

返回 true 或者 false

```elixir
Enum.member?([11,22,33,44], 33)
```

### 全部满足

返回 true 或者 false

```elixir
Enum.all?(["foo", "bar", "hello"], fn(s) ->
  String.length(s) === 3
end)
```

### 单个满足

有一个满足就为 true

```elixir
Enum.any?(["foo", "bar", "hello"], fn(s) ->
  String.length(s) === 3
end)
```

### 过滤元素

留下满足条件的元素

```elixir
Enum.filter([11, 22, 33], fn x ->
  rem(x, 2) === 0
end)
```

过滤掉满足条件的元素

```elixir
Enum.reject([111, 222, 333], fn x ->
  rem(x, 2) === 0
end)
```

### 获取元素

```elixir
Enum.fetch(["a", "b", "c", "d", "e"], 2)
Enum.at(["a", "b", "c", "d", "e"], 2)
```

### 获取大小

count

```elixir
Enum.count([11111, 2222, 333])
```

### 纯粹遍历

返回的是 :ok

```elixir
Enum.each(["a", "b", "c", "d", "e"], fn item ->
  item
end)
```

### 去重

```elixir
Enum.uniq([1, 2, 3, 3, 2, 1])
Enum.uniq_by([a: {:tea, 2}, b: {:tea, 2}, c: {:coffee, 1}], fn {_, y} -> y end)
```

相邻元素去重

```elixir
Enum.dedup([1, 2, 3, 3, 2, 1])
```

### 排序

```elixir
Enum.sort([11,22],
  fn(x, y) -> x > y
end)
```

### 计算频次

```elixir
Enum.frequencies([11111, 222, 222 , 2222, 333])
```

### 生成带 index 的 list

遍历的时候，需要获取 index 的时候，很有用

```elixir
Enum.with_index(["a", "b", "c", "d", "e"])
```

### 数组合并

也可用于 append

加到前面

```elixir
["d", "e" | ["a", "b", "c"]]
```

加到后面

```elixir
["a", "b", "c"] ++ ["d", "e"]
Enum.concat(["a", "b", "c"], ["d", "e"])
```

### 查找 index

```elixir
Enum.find_index(["a", "b", "c", "d", "e"], fn item ->
  item === "d"
end)
```

### 查找 value

```elixir
headers = [{"content-type", "application/json"}, {"x-custom-header", "some-value"}]
Enum.find_value(headers, fn {"content-type", value} ->
  value
end)
```

### 根据条件查找元素

找到第一个就停止，不会继续

```elixir
Enum.find([2,3,4,5], fn x -> rem(x, 2) === 1 end)
```

### 查找元素位置

找到第一个就停止，不会继续

```elixir
Enum.find_index([2222, 333], fn x -> rem(x, 2) === 1 end)
```

### 按个数删除

```elixir
Enum.drop([11111, 2222, 333], 2)
```

### 取一部分

2..3 为起始位和结束位置

```elixir
Enum.slice(["11", "22", "33", "44", "55"], 2..3)
```

### join 成 string

```elixir
Enum.join([11, 22, 33, 44])
Enum.join([11, 22, 33, 44], ".")
```

### reverse

```elixir
Enum.reverse([1, 2, 3], [4, 5, 6])
```

### max

```elixir
Enum.max([1, 2, 3])
Enum.max_by(["a", "aa", "aaa"], fn x -> String.length(x) end)
```

### 拆分

```elixir
Enum.split([1111, 2222, 3333], 2)
```

### replace

```elixir
defmodule EnumExt do
  def replace_at(list, index, value) do
    list
    |> Enum.with_index()
    |> Enum.map(fn
      # match index
      {_, ^index} -> value
      # anything else
      {value, _} -> value
    end)
  end
end
```

### 修改元素

修改每个元素

```elixir
Enum.map(["a", "b", "c", "d", "e"], fn item ->
  Enum.join([item, "-"], " ")
end)
```

### 循环加 break

第一次的 acc 为初始值

返回结果，二取一

```elixir
{:halt, xxx}
{:cont, xxx}
```

```elixir
list = [1, 3, 5, 2, 4, 6]

Enum.reduce_while(list, nil, fn item, acc ->
  case rem(item, 2) do
    0 ->
      {:halt, item * item}

    _ ->
      new_acc =
        case acc do
          nil ->
            100

          _ ->
            acc
        end

      IO.inspect(new_acc)
      {:cont, new_acc + 1}
  end
end)
```

### 遍历计算并返回结果

#### Enum.reduce

两种方式， 设置初始值和不设置初始值

共同点：

- 返回单个结果
- 每次循环结果存 result

不设置初始值：

- result 的初始值为第一个 item
- 只有一个元素，不会进入循环

```elixir
Enum.reduce([1, 2, 3, 4], fn item, result ->
  IO.inspect("each item #{item}, result #{result}")
  item + result
end)
```

设置初始值：

- result 的值为初始值
- 只有一个元素，一样会进循环

```elixir
Enum.reduce([11, 22, 33, 44], 1, fn item, result ->
  IO.inspect("each item #{item}, result #{result}")
  item + result
end)
```

#### Enum.map_reduce

- 返回 `{new_item, result}`
- 需设置 result 的初始值

```elixir
Enum.map_reduce([1, 2, 3], 0, fn item, result ->
  {item * 2, item + result}
end)

Enum.map_reduce(["aa", "bb", "cc"], "", fn item, saved_item ->
  IO.inspect("each save_item #{saved_item}")
  {item <> "-", saved_item <> item}
end)
```

map_reduce 实际上就是调用 erlang 的 `lists:mapfoldl`

```erlang
lists:mapfoldl(
  fun(Item, SavedItem) ->
    {Item ++ "-", SavedItem ++ Item}
  end,
  "",
  ["aa", "bb", "cc"]
).
```
