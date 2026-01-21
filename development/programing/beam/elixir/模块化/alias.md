# alias

## 说明

就是别名，需要输入最后一个模块名

## 例子

作用和 import 一样，区别是为 **模块** 创建别名，可以减少输入

- 定义测试模块

```elixir
defmodule DemoMod do
  defmodule DemoMod1 do
    def a(a, b) do
      a + b
    end
  end

  defmodule DemoMod2 do
    def b(a, b) do
      a + b
    end
  end
end
```

### 单 alias

默认 alias 会取模块名字的最后一部分作为别名

```elixir
defmodule Demo do
  alias DemoMod.DemoMod1

  def aaa do
    DemoMod1.a(1, 2)
  end
end
```

### 起个别名

使用 as 指定别名。

```elixir
defmodule Demo do
  alias DemoMod.DemoMod2, as: Hi

  def bbb do
    Hi.b(1, 2)
  end
end

```

### 多 alias

```elixir
defmodule Demo do
  alias DemoMod.{DemoMod1, DemoMod2}

  def ccc do
    a = DemoMod1.a(1, 2)
    b = DemoMod2.b(1, 2)
    a + b
  end
end
```
