# floki

## 说明

html 解析库

## 用法

### 安装

```elixir
defp deps do
  [
    {:floki, "~> 0.38.0"}
  ]
end
```

### 代码

```elixir
{:ok, document} = Floki.parse_document(html)
document
  |> Floki.find("p.headline")
  |> Floki.raw_html()
```

### 测试

```shell
iex --name aaa@127.0.0.1 --cookie 123456 -S mix
iex --name bbb@127.0.0.1 --cookie 123456 -S mix
```
