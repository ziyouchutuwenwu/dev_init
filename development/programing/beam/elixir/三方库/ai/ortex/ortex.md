# ortex

## 说明

跑 onnx 格式的模型

最佳实践：打包的时候，把 cuda 的支持一起打包进去，发布的时候，通过环境变量决定以什么模式启动

需要 rust 环境

## 例子

### cudnn

```sh
uv venv extra_libs

# libcudnn.so.9
uv pip install nvidia-cudnn-cu12
```

### 准备

生成测试模型

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

```sh
{:ortex, "~> 0.1.10"}
```

```sh
export ORTEX_TARGET=gpu

mix deps.get
mix compile

# 把 libonnxruntime_xxx.so 都复制到 ortex 目录
cp -RLf deps/ortex/native/ortex/target/release/libonnxruntime*.so deps/ortex/priv/native/
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
      require Logger

      def load(model_path) do
        app = unquote(config_app)
        settings = Application.get_env(app, :ortex_global)
        providers = settings[:providers]
        Logger.debug("providers #{inspect(providers)}")
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

  def demo do
    model = Demo.load("./model/model.onnx")
    Logger.debug("#{inspect(model)}")

    Logger.debug("正在构建 1x3 的输入张量...")
    input_tensor = Nx.broadcast(2.0, {1, 3})

    Logger.debug("正在执行推理...")
    result = Ortex.run(model, input_tensor)
    Logger.debug("结果 #{inspect(result)}")
  end
end
```

### 运行

动态库的路径

```sh
# 把 python 环境里面的 lib/python3.12/site-packages/nvidia 目录复制出来
export BASE_PATH=nvidia
export LIB_PATHS=$(find "$BASE_PATH" -name "*.so*" -exec dirname {} \; 2>/dev/null | sort -u | paste -sd:)
export LD_LIBRARY_PATH="$LIB_PATHS:$LD_LIBRARY_PATH"
```

如果有 cudnn 找不到，则回退到 cpu, 无任何提示和 log

```sh
ldd deps/ortex/priv/native/libonnxruntime_providers_cuda.so | rg "not found"
```
