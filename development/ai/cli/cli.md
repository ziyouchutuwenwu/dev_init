# cli

## 说明

能用 rtk 的一定要用，省 token

## 列表

### aider

用于代码精细控制，项目内必须用 git

```sh
uv tool install aider-chat
```

模型相关配置

```sh
export AIDER_MODEL="deepseek/deepseek-v4-flash"
export AIDER_EDITOR_MODEL="deepseek/deepseek-v4-flash"
export DEEPSEEK_API_KEY="xxxxxxxxxxxxxxxxxxxxxx"
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
# 通用配置
architect: true

cache-prompts: true
stream: false

chat-language: zh

# 编辑相关
git: true
# commit 以后，/diff 才有效果，/diff 的高亮依赖 git
auto-commits: false
# 回复的代码块的高亮，和 /diff 无关
code-theme: one-dark
#code-theme: nord
pretty: true

verify-ssl: false
check-update: false
show-model-warnings: false
```

### codewhale

两者之间

```sh
npm install -g codewhale
```

```sh
export DEEPSEEK_API_KEY="xxxxxxxxxxxxxxxxxxxxxx"
export DEEPSEEK_MODEL="deepseek-v4-flash"
```

### codex

协议不一样，需要转发

```sh
npm install -g @classicicn/codex-transfer
```

```sh
npm install -g @openai/codex
```

~/.codex-transfer/config.json

```json
{
  "modelMap": {
    "gpt-5.5": "deepseek-v4-flash",
    "codex-auto-review": "deepseek-v4-flash"
  }
}
```

~/.codex/config.toml

```toml
model_provider = "proxy"
model = "gpt-5.5"

[model_providers.proxy]
name = "proxy"
base_url = "http://127.0.0.1:4444/v1"
wire_api = "responses"
requires_openai_auth = false
```

```sh
# codex-transfer 用这个
export CODEX_TRANSFER_API_KEY=$DEEPSEEK_API_KEY
codex-transfer -d -k -u https://api.deepseek.com/v1
```

### claude code

用于项目攻坚，接 [deepseek](https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code)

```sh
npm install -g @anthropic-ai/claude-code
```

### opencode

通用，支持的厂商最多

```sh
npm i -g opencode-ai@latest
```

api

```sh
opencode providers list
```

### pi agent

办公自动化

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```
