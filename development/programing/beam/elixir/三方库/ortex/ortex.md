# ortex

## 说明

跑 onnx 格式的模型的

## 例子

deps

```elixir
{:ortex, "~> 0.1.10"}
```

runtime.exs

```elixir
import Config

all_possible_providers = [:tensorrt, :cuda, :rocm, :coreml, :directml]

target =
  case System.get_env("ORTEX_TARGET") do
    "cpu_full" ->
      %{providers: [:cpu], cpu_mode: :full}

    "cuda" ->
      %{providers: [:tensorrt, :cuda]}

    "rocm" ->
      %{providers: [:rocm]}

    "mac" ->
      %{providers: [:coreml]}

    "all" ->
      %{providers: all_possible_providers}

    _ ->
      %{providers: [:cpu], cpu_mode: :auto}
  end

# 修改 app 名字
config :demo, :ortex_global, target
```

代码

```elixir
defmodule OrtexExt.CpuConfig do
  def config(:full) do
    System.schedulers_online()
  end

  def config(:auto) do
    total_cores = System.schedulers_online()

    cond do
      total_cores <= 2 -> 1
      total_cores <= 8 -> total_cores - 2
      true -> trunc(total_cores * 0.75)
    end
  end

  def config(_) do
    config(:auto)
  end
end
```

```elixir
defmodule OrtexExt.ModelSpeeder do
  defmacro __using__(opts) do
    config_app = Keyword.get(opts, :config_app)

    quote do
      def load(model_path) do
        app = unquote(config_app)

        settings = Application.get_env(app, :ortex_global)

        providers = settings[:providers]

        Ortex.load(model_path, providers)
      end
    end
  end
end
```

调用

```elixir
defmodule Demo do
  use OrtexExt.ModelSpeeder, config_app: :demo
  require Logger

  def demo() do
    model = Demo.load("model_cls.onnx")

    Logger.debug("正在构建 1x3x224x224 的伪图像输入张量...")
    dummy_image = Nx.broadcast(0.5, {1, 3, 224, 224}) |> Nx.as_type(:f32)

    Logger.debug("正在执行推理...")
    {output_tensor} = Ortex.run(model, dummy_image)

    Logger.debug("\n--- 模型推理成功 ---")
    IO.inspect(Nx.shape(output_tensor), label: "输出张量的形状 (Shape)")
    IO.inspect(Nx.slice(output_tensor, [0, 0], [1, 5]), label: "输出的前 5 个特征数据值")
  end
end
```
