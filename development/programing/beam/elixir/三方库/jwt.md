# jwt

地址在[这里](https://github.com/joken-elixir/joken)

## 例子

```elixir
defmodule MyCustomAuth do
  use Joken.Config

  @impl true
  def token_config do
    # %{}
    default_claims(default_exp: 60 * 60, iss: "My custom issuer", aud: "aaaaaaaaaa")
    |> add_claim("my_key", "My custom claim")
  end
end

signer = Joken.Signer.create("HS256", "secret")
{:ok, token, claims} = MyCustomAuth.generate_and_sign(%{}, signer)

extra_claims = %{"user_id" => "some_id"}
token1 = MyCustomAuth.generate_and_sign!(extra_claims, signer)
{:ok, claims} = MyCustomAuth.verify_and_validate(token1, signer)
```
