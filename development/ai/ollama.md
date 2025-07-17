# ollama

## 步骤

一些环境变量

```sh
# 自定义地址
export OLLAMA_HOST=0.0.0.0:12345

# 模型在所有 gpu 上调度
export OLLAMA_SCHED_SPREAD=1

# 深度学习，提高计算效率和内存使用率
export OLLAMA_FLASH_ATTENTION=1

# 并行请求数，一般为 gpu *1.5
export OLLAMA_NUM_PARALLEL=3
```

```sh
ollama serve
```

```sh
ollama pull deepseek-r1:70b
ollama run deepseek-r1:70b --verbose
ollama stop deepseek-r1:70b
```

### 测试

```sh
curl http://10.0.0.9:12345/api/generate -d '{
    "model": "deepseek-r1:70b",
    "prompt": "帮我写一个年终总结"
}'
```
