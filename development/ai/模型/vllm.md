# vllm

## 说明

一个 vllm 版本，对应多个版本的 pytorch

一个 pytorch 版本，对应多个版本的 vllm

## 用法

[安装](https://vllm.ai/)

```sh
# --torch-backend 用 auto 并不准确
# vllm 的版本需要手动限制，否则装的是最新版
uv pip install vllm==0.10 --torch-backend cu126
```

查看版本

```sh
uv pip list | rg xxx
```

启动

```sh
# 指定哪几张卡
export CUDA_VISIBLE_DEVICES=0,1

# -tp 是说，用几张卡
uv run vllm serve "Qwen/Qwen2-VL-2B-Instruct" \
  --host 0.0.0.0 \
  --port 12345 \
  --trust-remote-code \
  --dtype half \
  --max-model-len 16384 \
  --gpu-memory-utilization 0.90 \
  --enforce-eager \
  -tp 2
```

补充

```sh
uv add 'transformers>=4.51.0,<5.0.0"'
```
