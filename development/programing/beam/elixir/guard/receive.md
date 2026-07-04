# 函数子句

## 说明

guard 跟在 when 后面

## 例子

```elixir
defmodule Demo do
  def send_msg(msg) do
    pid = self()
    send(pid, msg)
  end

  def receive_msg do
    receive do
      n when is_integer(n) and n > 0 ->
        IO.puts("收到正整数: #{n}")

      s when is_binary(s) ->
        IO.puts("收到字符串: #{s}")
    after
      1000 ->
        IO.puts("1秒内没有消息")
    end
  end
end
```

测试

```elixir
Demo.send_msg(42)
Demo.send_msg("hello")

Demo.receive_msg()
Demo.receive_msg()
```
