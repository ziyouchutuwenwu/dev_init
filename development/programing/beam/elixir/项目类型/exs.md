# exs

## 说明

exs 脚本，不需要编译，直接运行，需要安装 elixir

## 例子

lib/demo.exs

```elixir
defmodule Demo do
  def aaa do
    111
  end

  def bbb do
    222
  end
end
```

lib/aaa.exs

```elixir
Code.require_file("./demo.exs", __DIR__)

defmodule Xxx do
  def ccc do
    Demo.aaa()
  end

  def ddd do
    Demo.bbb()
  end
end

require Logger

args = System.argv()
Logger.debug("参数列表 #{inspect(args)}")
result1 = Xxx.ccc()
Logger.debug("结果 #{inspect(result1)}")
```

运行

```sh
mix run lib/aaa.exs 参数1 参数2
```
