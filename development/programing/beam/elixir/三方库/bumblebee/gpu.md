# gpu

## 说明

需要 gpu 的支持

## 步骤

### 显卡相关

```sh
sudo pacman -S cuda cudnn
```

### 编译

```sh
# manjaro下 ok
export CUDA_HOME=/opt/cuda
export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_HOME"
export PATH=/opt/cuda/bin:$PATH

mix deps.clean exla --build
mix deps.compile exla
```

### 代码

```elixir
Nx.global_default_backend({EXLA.Backend, client: :cuda})
```
