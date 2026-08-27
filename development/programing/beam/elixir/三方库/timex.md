# timex

## 说明

默认会引入 tzdata 库, 可以根据时区获取时间

另外可以把时间字符串转换为时间类型

需要在非中文目录内运行，否则会报错

## 步骤

mix.exs

```elixir
{:timex, "~> 3.0"}
```

代码

```elixir
Timex.now("Asia/Shanghai")
Timex.parse("2013-03-05 11:12:32", "%Y-%m-%d %H:%M:%S", :strftime)
```
