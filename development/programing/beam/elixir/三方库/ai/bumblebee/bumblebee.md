# bumblebee

## 例子

```elixir
{:bumblebee, "~> 0.7.0"},
{:exla, ">= 0.0.0"}
```

```elixir
defmodule Demo do
  def demo do
    {:ok, model_info} = Bumblebee.load_model({:hf, "google-bert/bert-base-uncased"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "google-bert/bert-base-uncased"})

    serving = Bumblebee.Text.fill_mask(model_info, tokenizer)
    Nx.Serving.run(serving, "The capital of [MASK] is Paris.")
  end
end
```
