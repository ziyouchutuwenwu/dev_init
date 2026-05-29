# cli

## 列表

### aider

用于精细控制

```sh
uv tool install aider-chat
```

查看模型名

```sh
KEY="xxx"
curl -L -X GET "https://api.deepseek.com/models" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $KEY"
```

.aider.conf.yml

```yaml
# 默认
model: deepseek/deepseek-v4-flash
# code 模式
editor-model: deepseek/deepseek-v4-flash

api-key:
  - deepseek = xxxxxxxxxxxxxxxxxxxxxx

architect: true
git: false
verify-ssl: false
check-update: false
show-model-warnings: false
analytics-disable: true
```

### claude code

用于攻坚，接 [deepseek](https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code)

```sh
npm install -g @anthropic-ai/claude-code
```

### codewhale

两者之间

```sh
npm install -g codewhale
```
