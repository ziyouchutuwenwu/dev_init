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

```elixir
url = "https://www.xxx.com/aa/bbb/query"
url
  |> URI.parse()
  |> URI.append_query(%{"aaa" => 111, "bbb" => 222} |> URI.encode_query())
  |> URI.append_query(%{"ccc" => 333, "ddd" => 444} |> URI.encode_query())
  |> to_string()
```
