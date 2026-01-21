# extrace

## 说明

recon 的封装

## 用法

### 目标节点

```sh
iex --sname aaa --cookie 111
```

```elixir
defmodule Demo do
  def aaa(a, b) do
    a + b
  end
end
```

### 当前节点

远程 shell 到 remote

```sh
iex --sname bbb --cookie 111 --remsh aaa@hp
```

#### 安装 deps

```elixir
Mix.install([
  {:extrace, "~> 0.3.0"}
])
```

#### trace 用法

启动 trace

```elixir
Extrace.calls(
  [
    {Demo, :aaa, fn _ -> :return end},
    {Enum, :take_random, fn _ -> :return end},
    {Enum, :count, fn _ -> :return end}
  ],
  100,
  scope: :local
)
```

关闭 trace

```elixir
Extrace.clear()
```

#### 执行语句

```elixir
Demo.aaa(111, 222)
Enum.take_random([1, 2, 3, 4], 200)
Enum.count([1, 2, 3, 4])
```
