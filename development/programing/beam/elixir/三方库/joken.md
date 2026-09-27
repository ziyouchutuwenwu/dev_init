# joken

## 说明

地址在 [这里](https://github.com/joken-elixir/joken)

## 例子

```elixir
defmodule TokenHelper do
  use Joken.Config

  @secret "kjoy3o1zeidquwy1398juxzldjlksahdk3"
  @salt "ai_data"
  @max_age 5 * 60

  @impl true
  def token_config do
    default_claims(
      iss: "my_app",
      aud: "client",
      default_exp: @max_age
    )
    |> add_claim("salt", fn -> @salt end, &(&1 == @salt))
  end

  def signer do
    Joken.Signer.create("HS256", @secret)
  end

  def create(user_id) do
    extra_claims = %{"user_id" => user_id}
    {:ok, token, _claims} = generate_and_sign(extra_claims, signer())
    token
  end

  def decrypt(token) do
    case verify_and_validate(token, signer()) do
      {:ok, claims} -> {:ok, claims["user_id"]}
      {:error, reason} -> {:error, reason}
    end
  end

  def do_sign(user_id), do: create(user_id)

  def do_verify(token) do
    case verify_and_validate(token, signer()) do
      {:ok, _claims} -> true
      {:error, _reason} -> false
    end
  end
end
```
