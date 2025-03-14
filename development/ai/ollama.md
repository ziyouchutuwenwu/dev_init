# ollama

## 步骤

```sh
export OLLAMA_HOST=0.0.0.0:12345
ollama serve

ollama pull deepseek-r1:70b
ollama run deepseek-r1:70b
ollama stop deepseek-r1:70b
```

### 测试

```sh
curl http://10.0.0.9:12345/api/generate -d '{
    "model": "deepseek-r1:70b",
    "prompt": "帮我写一个年终总结"
}'
```
