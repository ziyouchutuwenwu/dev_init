# benchee

## 说明

用于性能测试

## 例子

### 依赖

```elixir
{:benchee, "~> 1.3"},
{:jason, "~> 1.4"},
{:poison, "~> 5.0"},
{:simdjsone, "~> 0.2.2"},
{:jiffy, "~> 1.1"},
{:jsone, "~> 1.8"}
```

### 代码

lib/json_demo.ex

```elixir
defmodule JsonDemo do
  def json_map do
    json = File.read!("demo.json")
    :json.decode(json)
  end

  def json_string do
    File.read!("demo.json")
  end
end
```

benches/encode_sample.exs

```elixir
json_map = JsonDemo.json_map()

Benchee.run(%{
  ":json.encode/1" => fn ->
    json_map |> :json.encode() |> :erlang.iolist_to_binary()
  end,
  "Poison.encode!/1" => fn ->
    Poison.encode!(json_map)
  end,
  "Jason.encode!/1" => fn ->
    Jason.encode!(json_map)
  end,
  ":simdjson.encode/1" => fn ->
    :simdjson.encode(json_map)
  end,
  ":jiffy.encode/1" => fn ->
    :jiffy.encode(json_map)
  end,
  ":jsone.encode/1" => fn ->
    :jsone.encode(json_map)
  end
})
```

benches/decode_sample.exs

```elixir
json_string = JsonDemo.json_string()

Benchee.run(%{
  ":json.decode/1" => fn ->
    :json.decode(json_string)
  end,
  "Poison.decode!/1" => fn ->
    Poison.decode!(json_string)
  end,
  "Jason.decode!/1" => fn ->
    Jason.decode!(json_string)
  end,
  ":simdjson.decode/1" => fn ->
    :simdjson.decode(json_string)
  end,
  ":jiffy.decode/2" => fn ->
    :jiffy.decode(json_string, [:return_maps])
  end,
  ":jsone.decode/1" => fn ->
    :jsone.decode(json_string)
  end
})
```

### 运行

```sh
mix run benches/encode_sample.exs
mix run benches/decode_sample.exs
```
