# benchee

## 说明

用于性能测试

## 用法

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

lib/otp27_json.ex

```elixir
defmodule Otp27Json do
  @spec blockchain() :: map
  def blockchain do
    json = File.read!("blockchain.json")

    :json.decode(json)
  end

  @spec blockchain_json() :: String.t()
  def blockchain_json do
    File.read!("blockchain.json")
  end
end
```

benches/encode_sample.exs

```elixir
blockchain = Otp27Json.blockchain()

Benchee.run(%{
  ":json.encode/1" => fn -> blockchain |> :json.encode() |> :erlang.iolist_to_binary() end,
  "Poison.encode!/1" => fn -> Poison.encode!(blockchain) end,
  "Jason.encode!/1" => fn -> Jason.encode!(blockchain) end,
  ":simdjson.encode/1" => fn -> :simdjson.encode(blockchain) end,
  ":jiffy.encode/1" => fn -> :jiffy.encode(blockchain) end,
  ":jsone.encode/1" => fn -> :jsone.encode(blockchain) end
})
```

benches/decode_sample.exs

```elixir
blockchain_json = Otp27Json.blockchain_json()

Benchee.run(%{
  ":json.decode/1" => fn -> :json.decode(blockchain_json) end,
  "Poison.decode!/1" => fn -> Poison.decode!(blockchain_json) end,
  "Jason.decode!/1" => fn -> Jason.decode!(blockchain_json) end,
  ":simdjson.decode/1" => fn -> :simdjson.decode(blockchain_json) end,
  ":jiffy.decode/2" => fn -> :jiffy.decode(blockchain_json, [:return_maps]) end,
  ":jsone.decode/1" => fn -> :jsone.decode(blockchain_json) end
})
```
