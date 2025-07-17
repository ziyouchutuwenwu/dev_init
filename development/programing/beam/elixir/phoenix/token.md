# token 验证

## 用法

```elixir
defmodule TokenHelper do
  @secret "kjoy3o1zeidquwy1398juxzldjlksahdk3"
  @salt "ai_data"
  @max_age 5 * 60

  # encrypt 和 decrypt 是一对，可以解密获取原始数据
  def create(user_id) do
    Phoenix.Token.encrypt(@secret, @salt, user_id, max_age: @max_age)
  end

  # {:ok, user_id}
  # {:error, :expired}
  # {:error, :invalid}
  def decrypt(token) do
    Phoenix.Token.decrypt(@secret, @salt, token, max_age: @max_age)
  end

  # sign 和 verify 是一对，仅仅用于验证
  def sign(user_id) do
    Phoenix.Token.sign(@secret, @salt, user_id, max_age: @max_age)
  end

  def verify(token) do
    case Phoenix.Token.verify(@secret, @salt, token, max_age: @max_age) do
      {:ok, _} ->
        true

      _ ->
        false
    end
  end
end
```
