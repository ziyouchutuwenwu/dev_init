# exla

## 说明

用于加速推理

| 厂商   | 生态 |
| ------ | ---- |
| nvidia | cuda |
| amd    | rocm |
| google | tpu  |
| cpu    | host |

最佳实践：打包的时候，把 cuda 的支持一起打包进去，发布的时候，通过环境变量决定以什么模式启动

## 例子

```elixir
defmodule Demo do
  require Logger

  def demo() do
    Logger.debug("正在初始化测试张量...")

    a = Nx.broadcast(1.5, {2000, 2000}) |> Nx.as_type(:f32)
    b = Nx.broadcast(2.0, {2000, 2000}) |> Nx.as_type(:f32)

    Logger.debug("正在调用 EXLA 编译器进行 GPU 矩阵乘法...")

    result = Nx.dot(a, b)
    Logger.debug("--- GPU 计算成功 ---")
    IO.inspect(Nx.slice(result, [0, 0], [2, 2]), label: "左上角 2x2 结果预览")
  end
end
```

runtime.exs

```elixir
import Config

if config_env() != :test do
  has_nvidia? = File.exists?("/dev/nvidia0") or System.find_executable("nvidia-smi") != nil
  runtime_target = System.get_env("EXLA_TARGET") || "auto"

  platform_configs = %{
    "cuda" => [
      platform: :cuda
      # preallocate: true,
      # memory_fraction: 0.4
    ],
    "host" => [
      platform: :host
      # intra_op_parallelism_threads: 2,
      # device_count: 4
    ]
  }

  {client_name, client_config} =
    case runtime_target do
      "cpu" ->
        {:host, platform_configs["host"]}

      "cuda" when has_nvidia? ->
        {:cuda, platform_configs["cuda"]}

      "auto" when has_nvidia? ->
        {:cuda, platform_configs["cuda"]}

      _ ->
        {:host, platform_configs["host"]}
    end

  config :exla, :clients, [{client_name, client_config}]
  config :nx, :default_backend, {EXLA.Backend, client: client_name}
  config :nx, :default_compiler, EXLA.Value
end
```

编译

```sh
export EXLA_TARGET=cuda

mix deps.clean exla
mix deps.get
mix deps.compile exla --force

mix release
```

运行

```sh
# nvcc 所在目录
# $CUDA_HOME/bin
export CUDA_HOME=/opt/cuda
export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_HOME"
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
```
