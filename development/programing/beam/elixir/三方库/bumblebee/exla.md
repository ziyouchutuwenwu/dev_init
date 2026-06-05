# exla

## 说明

用于加速推理

| 厂商   | 生态 |
| ------ | ---- |
| nvidia | cuda |
| amd    | rocm |
| google | tpu  |
| cpu    | host |

## 配置

以 cuda 为例

```sh
# nvcc 所在目录
# which nvcc
export CUDA_HOME=/opt/cuda
export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_HOME"
export PATH="$CUDA_HOME/bin:$PATH"
export EXLA_TARGET=cuda
```

runtime.exs

```elixir
import Config

# 检测 EXLA_TARGET，没有则退回到 host
# host 为 cpu
# cuda 为 nvidia
# rocm 为 amd
# tpu 为 google 的
exla_target = System.get_env("EXLA_TARGET") || "host"


{client_name, platform_atom} =
  case exla_target do
    "cuda" -> {:cuda, :cuda}
    "rocm" -> {:rocm, :rocm}
    "tpu"  -> {:tpu, :tpu}
    _      -> {:host, :host}
  end

config :nx, :default_backend, {EXLA.Backend, client: client_name}
config :nx, :default_compiler, EXLA.Value

config :exla, :clients, [
  {client_name, [platform: platform_atom]}
]
```
