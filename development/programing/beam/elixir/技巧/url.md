# url

## 用法

### 地址合并

最后的地址

```sh
"https://www.xxx.com/aa/xx.html"
```

```elixir
base_url = "https://www.xxx.com/aa/bbb/"
path = "../xx.html"
base_url |> URI.parse |> URI.merge(path) |> to_string()
```

### 查询参数合并

重复参数不去重，会叠加

```elixir
url = "https://www.xxx.com/aa/bbb/query"
url
  |> URI.parse()
  |> URI.append_query(%{"aaa" => 111, "bbb" => 222} |> URI.encode_query())
  |> URI.append_query(%{"ccc" => 333, "ddd" => 444} |> URI.encode_query())
  |> to_string()
```

重复参数去重

```elixir
url = "https://www.xxx.com/xx/yy/query?aa=11&bb=22&cc=33"

uri = url |> URI.parse()
params = uri.query
  |> URI.query_decoder()
  |> Enum.to_list()
  |> Map.new()
  |> Map.put("bb", 44)

# 修改 query, 关键
new_uri = uri |> Map.put(:query, "")

full_url = new_uri |> URI.append_query(params |> URI.encode_query()) |> to_string()
```
