# aider

## 说明

用于代码精细控制，项目内必须用 git

## 配置

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
