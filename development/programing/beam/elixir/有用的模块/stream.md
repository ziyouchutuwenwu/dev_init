# stream

惰性 Enumerable 类型，用于避免在数据量大的时候爆内存

## 调试

调试的时候可以用 Enum 代替，比较方便

```elixir
stream |> Enum.to_list
```

## 例子

### flat_map

```elixir
Stream.flat_map(1..30, fn x -> [x, x * 2] end) |> Enum.to_list
```

### filter

```elixir
Stream.filter(11..1000//1, fn x ->
  rem(x, 2) == 0
end) |> Enum.to_list
```

### unfold

```elixir
Stream.unfold(5, fn
  0 ->
    nil
  n ->
    {n, n - 1}
end) |> Enum.to_list()
```

### with_index

```elixir
Stream.with_index([1, 2, 3]) |> Enum.to_list
Stream.with_index([1, 2, 3], 3) |> Enum.to_list
```

### 去重

整个去重

```elixir
Stream.uniq([1, 2, 3, 3, 2, 1]) |> Enum.to_list()
Stream.uniq_by([a: {:tea, 2}, b: {:tea, 2}, c: {:coffee, 1}], fn {_, y} -> y end) |> Enum.to_list()
```

相邻元素去重

```elixir
Stream.dedup([1, 2, 3, 3, 2, 1]) |> Enum.to_list()
```

### take

流里面获取部分数据

```elixir
Stream.take(1..1000_000_000, -5) |> Enum.to_list()
```

### take_while

```elixir
Stream.take_while(1..1000_000_000, &(&1 <= 5)) |> Enum.to_list
```

或者

```elixir
defmodule Demo do
  def on_while(data)do
    if data <=5 do
      true
    else
      false
    end
  end
end
Stream.take_while(1..1000_000_000, &Demo.on_while/1) |> Enum.to_list
```

### take_every

每隔 2 个元素分为一组，取第一个元素，拼接为 list

```elixir
Stream.take_every(1..10, 2) |> Enum.to_list
```

### drop_every

1 到 12 分每隔 3 个元素分为一组，删除掉每个组里面的第一个元素

```elixir
Stream.drop_every(1..12, 3) |> Enum.to_list()
```

### map_every

1 到 12 分每隔 3 个元素分为一组，每组里面第一个元素执行 fn 里面的函数

```elixir
Stream.map_every(1..12, 3, fn x -> x * 2 end) |> Enum.to_list()
```

### chunk_every

每隔 2 个元素分为一组,生成新元素

```elixir
Stream.chunk_every(1..6, 2) |> Enum.to_list()
```

### scan

```elixir
Stream.scan(1..5, 10, fn(item, acc) ->
  item + acc
end) |> Enum.to_list
```

### transform

处理相对复杂的逻辑

```elixir
start_count = 0
count = 5
Stream.transform(1001..9999, start_count, fn element, count ->
  if count < 5 do
   {[element*2], count + 1}
  else
    {:halt, count}
  end
end) |> Enum.to_list
```

### 流式读取文件

[参考链接](https://joyofelixir.com/11-files)

```elixir
"/tmp/demo" \
|> File.stream! \
|> Stream.map(&String.trim/1) \
|> Enum.to_list
```

### 流式文件替换

```elixir
File.stream!("/path/to/file")
|> Stream.map(&String.replace(&1, "#", "%"))
|> Stream.into(File.stream!("/path/to/other/file"))
|> Stream.run()
```

### 流式执行函数

```elixir
defmodule Demo do
  def demo(data)do
    IO.puts("aaaa #{inspect(data)}")
  end
end

# range 的用法
data_stream = 1..100_000_000//1
# data_stream = File.stream!("/xxx/big_file")
stream = Task.async_stream(data_stream, &Demo.demo/1, [max_concurrency: 100])
stream |> Stream.run
```

### 万能包装器

第二个函数必须是主动获取数据，而不是被动接收

```elixir
defmodule DemoStream do
  def open(file_name) do
    Stream.resource(
      fn ->
        _on_start(file_name)
      end,
      &_on_read/1,
      &_on_finish/1
    )
  end

  def _on_start(file_name) do
    File.open!(file_name)
  end

  def _on_read(file) do
    case IO.binread(file, :line) do
      data when is_binary(data) ->
        {[data], file}

      _ ->
        {:halt, file}
    end
  end

  def _on_finish(file) do
    File.close(file)
  end
end
```

用法

```elixir
"readme.md" |> DemoStream.open() |> Enum.to_list
```
