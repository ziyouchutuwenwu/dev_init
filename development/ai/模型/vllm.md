# vllm

## 说明

严格依赖 pytorch 的版本

## 用法

[安装](https://vllm.ai/)

启动

```sh
# 指定哪几张卡
export CUDA_VISIBLE_DEVICES=0,1

# -tp 是说，用几张卡
uv run vllm serve "Qwen/Qwen2-VL-2B-Instruct" \
  --host 0.0.0.0 \
  --port 12345 \
  --trust-remote-code \
  -tp 2
```
