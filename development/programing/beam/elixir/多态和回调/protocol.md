# protocol

用于数据多态

## 例子

```elixir
defprotocol DemoProtocol do
  @fallback_to_any true
  def aaa(data)
end

defimpl DemoProtocol, for: Integer do
  def aaa(data) do
    IO.inspect(data)
  end
end

defimpl DemoProtocol, for: Any do
  def aaa(data) do
    IO.puts("in any")
    IO.inspect(data)
  end
end

defmodule User do
  defstruct [:name, :age]
end

defimpl DemoProtocol, for: User do
  def aaa(data) do
    IO.inspect(data)
  end
end
```

## 测试

```elixir
DemoProtocol.aaa(111)

user = %User{:name => "rico", :age => 111}
DemoProtocol.aaa(user)
```
