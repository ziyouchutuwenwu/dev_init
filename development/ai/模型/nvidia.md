# nvidia

## 步骤

```sh
apt install nvidia-cuda-toolkit
```

exla 需要 nccl, nvshmem

非常的麻烦，用猥琐的办法解决

```sh
uv pip install nvidia-nccl-cu12 nvidia-nvshmem-cu12 nvidia-cudnn-cu12
```

```sh
export XLA_TARGET=cuda12

export CUDA_HOME=/opt/cuda
export PATH="$CUDA_HOME/bin:$PATH"

# 用 python 跑出来的依赖，比较省力
export EXTRA_LIB_BASE="/home/mmc/projects/python/demo/.venv/lib/python3.12/site-packages/nvidia"
export EXTRA_LIB_PATHS=$(find "$EXTRA_LIB_BASE" -name "*.so*" -exec dirname {} \; 2>/dev/null | sort -u | paste -sd:)
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$EXTRA_LIB_PATHS:$LD_LIBRARY_PATH"

export XLA_FLAGS="--xla_gpu_cuda_data_dir=$CUDA_HOME"
export ELIXIR_ERL_OPTIONS="+sssdio 128"
```
