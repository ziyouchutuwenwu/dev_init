# bumblebee

## 说明

bumblebee 的 github 上有文章，提到公告视频，点过去，是一篇文章，里面提到 livebook 和 bumblebee 的集成

## 步骤

照抄 kino_bumblebee 的依赖也可以

```elixir
Mix.install([
  {:bumblebee, "~> 0.6.0"},
  {:kino, "~> 0.13"},
  {:nx, "~> 0.7"},
  {:exla, "~> 0.7", only: [:dev, :test]},
  {:ex_doc, "~> 0.29", only: :dev, runtime: false}
])
```
