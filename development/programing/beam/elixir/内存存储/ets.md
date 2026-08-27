# ets

## 例子

```elixir
defmodule TokenEts do
  @table :user_token
  def init() do
    :ets.new(@table, [:set, :public, :named_table])
  end

  def delete_table do
    :ets.delete(@table)
  end

  def get(token) do
    case :ets.lookup(@table, token) do
      [{_token, user_id}] ->
        user_id

      _ ->
        ""
    end
  end

  # insert 的 第一个元素为 key
  def set(token, user_id) do
    :ets.insert(@table, {token, user_id})
  end

  def delete(token) do
    :ets.delete(@table, token)
  end
end
```
