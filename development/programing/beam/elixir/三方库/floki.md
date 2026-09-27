# floki

## 说明

html 解析库

## 用法

依赖

```elixir
defp deps do
  [
    {:floki, "~> 0.38.0"}
  ]
end
```

代码

```elixir
{:ok, document} = Floki.parse_document(html)
document
  |> Floki.find("p.headline")
  |> Floki.raw_html()
```
