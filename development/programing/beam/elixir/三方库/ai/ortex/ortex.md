# ortex

## 说明

跑 onnx 格式的模型

最佳实践：打包的时候，把 cuda 的支持一起打包进去，发布的时候，通过环境变量决定以什么模式启动

## 例子

### 准备

```python
import torch
import torch.nn as nn

class TinyModel(nn.Module):
    def forward(self, x):
        return x * 2.0

# 导出极其微小的 ONNX 文件
torch.onnx.export(TinyModel(), torch.randn(1, 3), "model.onnx")
print("超微型测试模型生成成功！")
```

### 配置

deps

```elixir
{:ortex, "~> 0.1.10"}
```

config.exs

```elixir
import Config

# 编译的时候，把 cuda 链接进去
# features 里面的字段顺序比较重要
config :ortex, Ortex.Native, features: [:tensorrt, :cuda]
# config :ortex, Ortex.Native, features: [:rocm]
# config :ortex, Ortex.Native, features: [:coreml]
```

runtime.exs

```elixir
import Config

if config_env() != :test do
  has_nvidia? = File.exists?("/dev/nvidia0") or System.find_executable("nvidia-smi") != nil

  providers =
    case System.get_env("ORTEX_TARGET") do
      "cpu" -> [:cpu]
      "gpu" when has_nvidia? -> [:tensorrt, :cuda]
      "auto" when has_nvidia? -> [:tensorrt, :cuda]
      _ -> [:cpu]
    end

  config :demo, :ortex_global, providers: providers
end
```

代码

```elixir
defmodule OrtexModel do
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
  use OrtexModel, config_app: :demo
  require Logger

  def demo() do
    model = Demo.load("model/model.onnx")

    Logger.debug("正在构建 1x3x640x640 的伪图像输入张量...")
    dummy_image = Nx.broadcast(0.5, {1, 3, 640, 640}) |> Nx.as_type(:f32)

    Logger.debug("正在执行推理...")

    outputs = Ortex.run(model, dummy_image)
    output_tensor = if is_tuple(outputs), do: elem(outputs, 0), else: outputs

    Logger.debug("\n--- 模型推理成功 ---")
    IO.inspect(Nx.shape(output_tensor), label: "输出张量的形状 (Shape)")

    flat_preview = output_tensor |> Nx.flatten() |> Nx.slice([0], [5])
    IO.inspect(flat_preview, label: "输出张量的前 5 个特征值预览")
  end
end
```
